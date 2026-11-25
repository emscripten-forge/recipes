#!/usr/bin/env bash
set -euxo pipefail

# ---------------------------------------------------------------------------
# Scilab for emscripten-wasm32, with its Java GUI (console, SciNotes, figures,
# Xcos, help browser, variable/file browsers) running on the openjdk21
# package: OpenJDK 21 (Zero) and AWT/Swing on x11.wasm, linked statically
# into the same shared-memory (pthreads) WebAssembly module as Scilab.
#
# The link scripts, the Fortran driver and the runtime glue come from the
# scilab-wasm-kit source (kit/); the libraries are packages (fftw,
# hdf5-static, matio-static, suitesparse-pthread, liblapack...).
#
#   1. the libcurl subset of the kit (curl-shim)
#   2. configure + make: Scilab's C/C++/Fortran as static archives, its Java
#      code with Ant (the host JDK), localization files
#   3. node build of scilab-cli (no JVM): compiles the Scilab macros
#   4. the browser module (scilab.js/.wasm), linked with libjvm & co
#   5. the data files the page loads (Scilab tree, JDK image), the page
#
# Stages leave markers in $SRC_DIR/_stamps so a local rebuild resumes.
# ---------------------------------------------------------------------------

JOBS="${CPU_COUNT:-2}"
WASM_KIT="$SRC_DIR/kit"
GLUE="$SRC_DIR/_glue"                    # libcurl subset, omp.h: build only
STAMPS="$SRC_DIR/_stamps"
SCI_SRC="$SRC_DIR/scilab"
SCI_BIN="$SRC_DIR/scilab-bin"            # official Linux binary: jars, help
OUT_SHARE="$PREFIX/share/scilab-wasm"
mkdir -p "$GLUE/lib" "$GLUE/include" "$GLUE/bin" "$STAMPS"

EMSDK_LLVM_BIN="$(em-config LLVM_ROOT)"
export NM="$EMSDK_LLVM_BIN/llvm-nm"

# SLICOT (mb03od) calls DGEQPF, one of the routines LAPACK deprecated: it is
# in liblapack from the lapack recipe's build 5 (BUILD_DEPRECATED=ON). The
# programs are linked with undefined symbols allowed, so without it they
# would only fail when rankqr & co. are called. (Through a file: with
# pipefail, grep -q stopping at the match would fail nm with SIGPIPE.)
"$NM" --defined-only "$PREFIX/lib/liblapack.a" > "$SRC_DIR/_liblapack-symbols.txt"
if ! grep -q " T dgeqpf_$" "$SRC_DIR/_liblapack-symbols.txt"; then
  echo "liblapack has no DGEQPF: it must be built with BUILD_DEPRECATED=ON (lapack build >= 5)" >&2
  exit 1
fi
export AR=emar RANLIB=emranlib CC=emcc CXX=em++

# The JVM's threads are pthreads, so the whole program is one shared-memory
# module and Scilab is compiled with -pthread. Most static archives of the
# packages are not, and need not be: wasm-ld only refuses objects compiled
# without it that had atomics, TLS or setjmp lowered (SuiteSparse's METIS
# does setjmp: hence suitesparse-pthread).
export CFLAGS="-O2 -pthread"
export CXXFLAGS="-O2 -pthread"
# hdf5-static, matio-static and suitesparse-pthread are installed in their
# own directories
LIBDIRS="-L$GLUE/lib -L$PREFIX/lib/matio-static -L$PREFIX/lib/hdf5-static -L$PREFIX/lib/suitesparse-pthread -L$PREFIX/lib"
export LDFLAGS="-pthread $LIBDIRS"
# -DNDEBUG: configure only adds it (DEBUG_CFLAGS/DEBUG_CXXFLAGS) for the
# compilers it knows by name, gcc and clang, not emcc/em++; without it the
# AST is built with its debug object inspector (and asserts).
# (and the libraries in their own directories: SUNDIALS' KLU solver includes
# suitesparse/klu.h without configure's KLU_CFLAGS)
export CPPFLAGS="-DNDEBUG -I$GLUE/include -I$PREFIX/include/matio-static -I$PREFIX/include/hdf5-static -I$PREFIX/include/suitesparse-pthread -I$PREFIX/include -I$PREFIX/include/ncurses"

# Fortran: flang through flang-wasm (COMMON blocks, linking)
export FLANG_WASM_FLANG="$(command -v flang)"
export F77="$WASM_KIT/flang-wasm" FC="$WASM_KIT/flang-wasm"
export FFLAGS="-O2"
export FLIBS="-lflang_rt.runtime"
export FLANG_WASM_COMMONS_DIR="$SRC_DIR/_fortran_commons"
chmod +x "$WASM_KIT/flang-wasm"

# pkg-config: only the wasm prefixes
export PKG_CONFIG_LIBDIR="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig"
unset PKG_CONFIG_PATH || true

# host JDK (javac, ant) for Scilab's Java code
export JAVA_HOME="$BUILD_PREFIX/lib/jvm"
[ -x "$JAVA_HOME/bin/javac" ] || export JAVA_HOME="$BUILD_PREFIX"
unset JAVA_TOOL_OPTIONS || true

# ---------------------------------------------------------------------------
# 1. build-time glue
# ---------------------------------------------------------------------------
# libcurl subset over synchronous XMLHttpRequest (http_get & co, getURL),
# from the kit: there is no network stack under the browser's
if [ ! -f "$GLUE/lib/libcurl.a" ]; then
  mkdir -p "$GLUE/include/curl" "$SRC_DIR/_curl"
  cp "$WASM_KIT/curl-shim/include/curl/curl.h" "$GLUE/include/curl/"
  emcc $CFLAGS -I"$GLUE/include" -c "$WASM_KIT/curl-shim/curl-shim.c" -o "$SRC_DIR/_curl/curl-shim.o"
  emar rcs "$GLUE/lib/libcurl.a" "$SRC_DIR/_curl/curl-shim.o"
  sed "s|@PREFIX@|$GLUE|" "$WASM_KIT/curl-shim/curl-config.in" > "$GLUE/bin/curl-config"
  chmod +x "$GLUE/bin/curl-config"
fi

# SUNDIALS' OpenMP vector is built in any case (Scilab uses it with
# several threads); without -fopenmp its pragmas are ignored and the header
# it includes is all it needs
if [ ! -f "$GLUE/include/omp.h" ]; then
  echo "/* no OpenMP for emscripten: #pragma omp is ignored, code runs serially */" > "$GLUE/include/omp.h"
fi

# ---------------------------------------------------------------------------
# 2. configure and build Scilab
# ---------------------------------------------------------------------------
cd "$SCI_SRC"

# Java third parties come from the official binary of the same version (the
# Scilab-specific builds of jrosetta, flexdock, jgraphx, skinlf... are not
# published anywhere else); JOGL, gluegen, JCEF and JavaFX are only needed to
# compile -- their native parts are never loaded here.
if [ ! -f "$STAMPS/thirdparty" ]; then
  mkdir -p thirdparty/fonts
  cp "$SCI_BIN"/thirdparty/*.jar thirdparty/
  cp "$SCI_BIN"/thirdparty/scilabsymbols.ttf thirdparty/fonts/ 2>/dev/null || true
  touch "$STAMPS/thirdparty"
fi

if [ ! -f "$STAMPS/configure" ]; then
  # the version a release build names itself with ("Scilab 2026.1.0"; the
  # tag's sources say "scilab-branch-2026.1")
  # (version.h is made from version.h.in by configure)
  sed -i -e "s|SCI_VERSION_STRING \".*\"|SCI_VERSION_STRING \"scilab-$PKG_VERSION\"|" \
         -e "s|SCI_VERSION_WIDE_STRING L\".*\"|SCI_VERSION_WIDE_STRING L\"scilab-$PKG_VERSION\"|" \
      modules/core/includes/version.h.in
  echo "SCIVERSION=scilab-$PKG_VERSION" > Version.incl

  # configure.ac and Makefile.am files are patched; regenerate with this
  # libtool, which also knows emscripten
  autoreconf -fi

  # results configure cannot run programs to find out when cross-compiling
  # (the arpack check assumes it works when cross-compiling)
  export ac_cv_func_malloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes
  export ac_cv_java_jvm_working_jni_link=yes
  # tgetent is in libtinfo, linked with libncurses in step 4
  export ac_cv_lib_ncurses_tgetent=yes
  # static SuiteSparse libraries need their dependencies to link; they are
  # all linked in step 4
  export ac_cv_lib_amd_amd_info=yes ac_cv_lib_umfpack_umfpack_di_solve=yes
  export ac_cv_lib_klu_klu_l_solve=yes
  # macros in emscripten's math.h, not functions configure can link
  export ac_cv_func_isinf=yes ac_cv_func_isnan=yes
  export ac_cv_func_memcmp_working=yes ac_cv_func_strtod=yes
  export ac_cv_func_lstat_dereferences_slashed_symlink=yes
  # emscripten's libc (musl) has gettext and reads .mo files, but is not
  # "GNU gettext" for gettext.m4
  export gt_cv_func_gnugettext1_libc=yes
  # the JVM of the program: openjdk21's headers; its archives are linked
  # into the program in step 4, not into the Scilab libraries
  export JAVA_JNI_INCLUDE_TARGET="-I$PREFIX/share/openjdk21-wasm/include"
  export JAVA_JNI_LIBS_TARGET=""

  ./configure \
      --prefix="$PREFIX" \
      --build=x86_64-pc-linux-gnu \
      --host=wasm32-unknown-emscripten \
      --enable-static --disable-shared \
      --enable-force-full-link \
      --with-jdk="$JAVA_HOME" \
      --with-ant="$BUILD_PREFIX" \
      --without-javasci \
      --without-tk \
      --without-modelica \
      --without-xlnt \
      --without-arrow \
      --with-umfpack-library="$PREFIX/lib/suitesparse-pthread" --with-umfpack-include="$PREFIX/include/suitesparse-pthread" \
      --with-klu-library="$PREFIX/lib/suitesparse-pthread" --with-klu-include="$PREFIX/include/suitesparse-pthread" \
      --without-openmp \
      --without-mpi \
      --disable-build-help \
      --with-curl="$GLUE" \
      --with-eigen-include="$PREFIX/include/eigen3" \
      --with-hdf5-include="$PREFIX/include/hdf5-static" --with-hdf5-library="$PREFIX/lib/hdf5-static" \
      --with-fftw-include="$PREFIX/include" --with-fftw-library="$PREFIX/lib" \
      --with-matio-include="$PREFIX/include/matio-static" --with-matio-library="$PREFIX/lib/matio-static" \
      --with-blas-library="$PREFIX/lib" --with-lapack-library="$PREFIX/lib" \
      --with-arpack-library="$PREFIX/lib" \
      --with-libxml2="$PREFIX" \
      || { tail -n 200 config.log; exit 1; }
  # The help is not built (--disable-build-help: that runs Scilab and Java
  # over every page; the official build's help jars are installed instead),
  # but the help browser and the help() functions are wanted: keep the
  # helptools module on. javasci (calling Scilab from Java) is not built.
  sed -i -e 's|<module name="helptools" activate="no"/>|<module name="helptools" activate="yes"/>|' \
         -e 's|<module name="javasci" activate="yes"/>|<module name="javasci" activate="no"/>|' \
      etc/modules.xml
  touch "$STAMPS/configure"
fi
# (local rebuilds: stop here)
[ "${SCILAB_WASM_STOP_AFTER:-}" != configure ] || exit 0

if [ ! -f "$STAMPS/make" ]; then
  # The libraries (static archives), the Java code (Ant, through each
  # module's "java" target) and the data files; the programs are linked in
  # steps 3 and 4 (the macros, built at the top level with scilab-cli, too)
  make -C modules -j"$JOBS"
  # main() of the two programs (built at the top level)
  make modules/startup/src/cpp/scilab_bin-scilab.o modules/startup/src/cpp/scilab_cli_bin-scilab.o
  make -C contrib -j"$JOBS"
  make -C desktop -j"$JOBS"
  make localization
  touch "$STAMPS/make"
fi

WASM_OUT="$SRC_DIR/_wasm"
export SCI_SRC PREFIX
export WORK="$SRC_DIR/_link"
# the libraries linked into both programs (static archives; wasm-ld resolves
# them in any order)
SCILAB_WASM_LIBS="$LIBDIRS -lmatio -lhdf5_hl -lhdf5 -lfftw3 -lcurl
  -lumfpack -lklu -lbtf -lamd -lcamd -lcolamd -lccolamd -lsuitesparseconfig
  -larpack -llapack -lblas -lflang_rt.runtime
  -lxslt -lexslt -lxml2 -lpcre2-32 -lpcre2-8 -larchive -lzstd -lbz2 -lz
  -lncurses -ltinfo -liconv -lcharset"
# libarchive's own dependencies, when it has any
for f in $(pkg-config --static --libs-only-l libarchive 2>/dev/null); do
  case " $SCILAB_WASM_LIBS " in *" $f "*) ;; *) SCILAB_WASM_LIBS="$SCILAB_WASM_LIBS $f" ;; esac
done
export SCILAB_WASM_LIBS="$(echo $SCILAB_WASM_LIBS)"

# Every direct call matches the definition of the function it calls (patch
# 0009). The kit's wasm-ld wrapper reports the calls wasm-ld finds with
# another signature (and would adapt them): here any is an error.
check_signatures() {
  local report="$WORK/signature-mismatches-$1.txt"
  if [ -s "$report" ]; then
    cat "$report" >&2
    echo "$1: functions called with another signature than their definition's" >&2
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# 3. scilab-cli for node (no JVM), and the macros (.bin) compiled with it
# ---------------------------------------------------------------------------
if [ ! -f "$STAMPS/cli" ]; then
  bash "$WASM_KIT/link-scilab.sh" cli "$WASM_OUT/cli/scilab-cli.js"
  check_signatures cli
  touch "$STAMPS/cli"
fi

if [ ! -f "$STAMPS/macros" ]; then
  mkdir -p "$SRC_DIR/_home"
  HOME="$SRC_DIR/_home" SCI="$SCI_SRC" node "$WASM_OUT/cli/scilab-cli.js" \
      -ns -noatomsautoload -nouserstartup -quit \
      -f modules/functions/scripts/buildmacros/buildmacros.sce
  nbin=$(find modules -path '*/macros/*.bin' | wc -l)
  echo "compiled macros: $nbin"
  [ "$nbin" -gt 2000 ]
  touch "$STAMPS/macros"
fi

# the index of the help pages that help() shows in the console (the help
# build makes it otherwise): page name -> XML source
if [ ! -f "$STAMPS/inline-help" ]; then
  HOME="$SRC_DIR/_home" SCI="$SCI_SRC" node "$WASM_OUT/cli/scilab-cli.js" \
      -ns -noatomsautoload -nouserstartup -quit \
      -e "generate_inline_links('en_US', SCI)"
  [ -s modules/core/inline/en_US/links.json ]
  touch "$STAMPS/inline-help"
fi

# ---------------------------------------------------------------------------
# 4. the browser module: Scilab, OpenJDK 21 and x11.wasm
# ---------------------------------------------------------------------------
if [ ! -f "$STAMPS/gui" ]; then
  bash "$WASM_KIT/link-scilab.sh" gui "$WASM_OUT/gui/scilab.js"
  check_signatures gui
  touch "$STAMPS/gui"
fi

# ---------------------------------------------------------------------------
# 5. install: the Scilab tree (SCI), the programs, the page
# ---------------------------------------------------------------------------
SCI_DIR="$PREFIX/share/scilab"
make install-data

# Java third parties: in SCI (one tree for the page to load), listed in
# classpath.xml relative to it rather than where configure found them
mkdir -p "$SCI_DIR/thirdparty/fonts"
python3 - "$SCI_DIR/etc/classpath.xml" "$SCI_SRC/thirdparty" "$SCI_DIR/thirdparty" <<'PY'
import os, re, shutil, sys
cp, src, dst = sys.argv[1:]
xml = open(cp).read()
used = set()
for d in sorted({src, os.path.realpath(src)}):   # (configure may have either)
    used |= set(re.findall(re.escape(d) + r'/([^"/]+\.jar)', xml))
    xml = xml.replace(d + '/', '$SCILAB/thirdparty/')
used = sorted(used)
for j in used:
    shutil.copy2(os.path.join(src, j), os.path.join(dst, j))
# entries of modules that are not built (javasci)
sci = os.path.dirname(os.path.dirname(cp))
def keep(m):
    return os.path.exists(os.path.join(sci, m.group(1)))
xml, n = re.subn(r'[ \t]*<path value="\$SCILAB/([^"]+\.jar)"\s*/>[ \t]*\n',
                 lambda m: m.group(0) if keep(m) else '', xml)
open(cp, 'w').write(xml)
print('classpath.xml: %d third-party jars' % len(used))
PY
if grep -q -e "$SCI_SRC" -e "$(realpath "$SCI_SRC")" "$SCI_DIR/etc/classpath.xml"; then
  echo "build paths left in classpath.xml"; exit 1
fi
cp "$SCI_SRC/thirdparty/fonts/scilabsymbols.ttf" "$SCI_DIR/thirdparty/fonts/" 2>/dev/null || true

# help() in the console: its index (the English pages' XML sources are in
# the tree)
cp -R "$SCI_SRC/modules/core/inline" "$SCI_DIR/modules/core/"

# help (JavaHelp jars) and its images from the official build: building them
# runs Scilab and Java over every help page and its examples
mkdir -p "$SCI_DIR/modules/helptools/jar"
for j in "$SCI_BIN"/share/scilab/modules/helptools/jar/scilab_*.jar; do
  cp "$j" "$SCI_DIR/modules/helptools/jar/"
done

# translations: in SCI/locale (Scilab's second place for them), so that they
# are in the tree the page loads
for mo in "$PREFIX"/share/locale/*/LC_MESSAGES/scilab.mo; do
  [ -f "$mo" ] || continue
  lang=$(basename "$(dirname "$(dirname "$mo")")")
  mkdir -p "$SCI_DIR/locale/$lang/LC_MESSAGES"
  mv "$mo" "$SCI_DIR/locale/$lang/LC_MESSAGES/"
  rmdir --ignore-fail-on-non-empty "$(dirname "$mo")" "$(dirname "$(dirname "$mo")")"
done

# the programs: the page's, and scilab-cli (node) that the tests run
mkdir -p "$OUT_SHARE"
install -m 644 "$WASM_OUT"/gui/scilab.{js,wasm} "$OUT_SHARE/"
install -m 644 "$WASM_OUT"/cli/scilab-cli.{js,wasm} "$OUT_SHARE/"

# the files the page loads: the Scilab tree and the JDK image (openjdk21's)
python3 "$WASM_KIT/pack-tree.py" "$SCI_DIR" "$OUT_SHARE/scilab-share" --root /usr/share/scilab \
    --exclude 'modules/*/tests' --exclude 'modules/*/locales' \
    --exclude 'modules/*/help/fr_FR' --exclude 'modules/*/help/ja_JP' \
    --exclude 'modules/*/help/pt_BR' --exclude 'modules/*/help/ru_RU' \
    --exclude 'modules/*/includes' --exclude 'modules/*/examples' \
    --exclude 'modules/helptools/jar/scilab_fr_FR_help.jar' \
    --exclude 'modules/helptools/jar/scilab_ja_JP_help.jar' \
    --exclude 'modules/helptools/jar/scilab_pt_BR_help.jar' \
    --exclude 'modules/helptools/jar/scilab_ru_RU_help.jar'
# the JDK image the page loads (copies: share/scilab-wasm is the whole site)
install -m 644 "$PREFIX/share/openjdk21-wasm/openjdk21-jre.json" \
               "$PREFIX/share/openjdk21-wasm/openjdk21-jre.data.gz" "$OUT_SHARE/"
install -m 644 "$WASM_KIT/web/scilab-web.js" "$WASM_KIT/web/index.html" "$OUT_SHARE/"
cp "$PREFIX/share/openjdk21-wasm/coi-serviceworker.js" "$OUT_SHARE/"

# nothing else of the build is installed (static archives, headers: there is
# no way to load compiled toolboxes or link() libraries; desktop integration
# files of the native application)
rm -rf "$PREFIX/lib/scilab" "$PREFIX/include/scilab" "$PREFIX/lib/pkgconfig/scilab.pc" \
       "$PREFIX/include/sundials" "$PREFIX/include/sunmatrix" "$PREFIX/include/nvector" \
       "$PREFIX/share/applications" "$PREFIX/share/mime" "$PREFIX/share/appdata" \
       "$PREFIX/share/icons"

# notices of what is linked into scilab.wasm / scilab-cli.wasm besides Scilab
LICDIR="$PREFIX/share/licenses/scilab"
mkdir -p "$LICDIR"
for pkg in hdf5-static matio-static suitesparse-pthread libffi-pthread; do
  if [ -d "$PREFIX/share/licenses/$pkg" ]; then
    mkdir -p "$LICDIR/$pkg"
    cp "$PREFIX/share/licenses/$pkg"/* "$LICDIR/$pkg/"
  fi
done
cat > "$LICDIR/THIRDPARTY.md" <<'NOTICE'
# Linked into scilab.wasm and scilab-cli.wasm

Scilab (GPL-2.0-only, COPYING; parts BSD-3-Clause, COPYING-BSD; the Java
third parties: ACKNOWLEDGEMENTS) is linked statically with these
emscripten-forge packages, whose license files are in the packages
themselves (and, where they ship one, in this directory):

| Package | License |
|---|---|
| openjdk21 (libjvm, class library natives; desktop module only) | GPL-2.0-only WITH Classpath-exception-2.0 |
| x11-wasm (desktop module only) | MIT AND X11 AND TCL AND ISC |
| libffi-pthread (desktop module only) | MIT |
| fftw | GPL-2.0-or-later |
| hdf5-static | BSD-3-Clause |
| matio-static | BSD-2-Clause |
| suitesparse-pthread (UMFPACK; KLU, BTF; AMD, CAMD, COLAMD, CCOLAMD, SuiteSparse_config) | GPL-2.0-or-later; LGPL-2.1-or-later; BSD-3-Clause |
| liblapack, libblas, arpack | BSD-3-Clause |
| libflang (flang_rt) | Apache-2.0 WITH LLVM-exception |
| libxml2, libxslt | MIT |
| pcre2 | BSD-3-Clause |
| libarchive | BSD-2-Clause |
| zstd, bzip2, zlib | BSD-3-Clause, bzip2-1.0.6, Zlib |
| ncurses | MIT |
| libiconv | LGPL-2.1-or-later |
| rapidjson, eigen (headers) | MIT, MPL-2.0 |
| scilab-wasm-kit (link-time glue, libcurl subset) | GPL-2.0-only |
NOTICE

#!/usr/bin/env bash
set -euxo pipefail

# polymake for emscripten-wasm32.
#
# polymake is a perl application with a large C++ core.  Natively it runs as
# `perl bin/polymake`, pulling in one shared module per application through
# DynaLoader.  The emscripten-forge perl is a static interpreter built with
# usedl='undef' / dlsrc='dl_none.xs' / dlext='none', so nothing can ever be
# dlopen'ed at runtime and that model does not survive the port.
#
# Instead this recipe builds the *callable* variant: pm::perl::Main constructs
# the perl interpreter from C++ and bootstraps all core XS modules statically
# through the generated polymakeBootstrapXS.h.  The patches turn every "shared
# module" into an ar archive, and this script performs one final link of the
# core, the callable glue, every application archive and libperl.a into a single
# wasm executable.  The rule files, perl libraries and application sources are
# packed into a filesystem image alongside it.
#
# The build is a cross build in the strict sense: the *native* perl from the
# build environment drives configure.pl, ExtUtils::xsubpp and the ninja target
# generator, while the emscripten perl in the host environment is only ever
# linked against, never executed.  polymake's own configure normally learns
# everything about perl from the interpreter running it, so the perl-specific
# part of the generated ninja configuration is rewritten for the target below.

# --------------------------------------------------------------------------
# toolchain
# --------------------------------------------------------------------------

strip_arch() { echo "${1:-}" | sed -E 's/-march=[^ ]+//g; s/-mtune=[^ ]+//g'; }

export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig"

# Makes the patched ConfigureStandalone.pm link the configuration test programs
# as node-runnable launchers and execute them through node, so that the probes
# for gmp, mpfr, flint, bliss, ppl, cddlib, lrslib, normaliz, nauty and
# libsingular actually run instead of failing as "cannot execute binary file".
export POLYMAKE_TEST_RUNNER="node"
export POLYMAKE_TEST_SUFFIX=".js"

BUILD_PERL="${BUILD_PREFIX}/bin/perl"
test -x "${BUILD_PERL}"

EMSCRIPTEN_DIR="$(dirname "$(readlink -f "$(command -v emcc)")")"
test -f "${EMSCRIPTEN_DIR}/tools/file_packager.py"

# --------------------------------------------------------------------------
# the target (emscripten) perl
# --------------------------------------------------------------------------

TARGET_PERL_ARCHLIB="$(ls -d "${PREFIX}"/lib/perl5/*/core_perl | head -n1)"
TARGET_PERL_CORE="${TARGET_PERL_ARCHLIB}/CORE"
TARGET_PERL_PRIVLIB="${PREFIX}/lib/perl5/core_perl"
TARGET_PERL_CONFIG="${TARGET_PERL_ARCHLIB}/Config_heavy.pl"

test -f "${TARGET_PERL_CORE}/libperl.a"
test -f "${TARGET_PERL_CORE}/perl.h"
test -f "${TARGET_PERL_CONFIG}"

# read a value out of the target perl's Config_heavy.pl
target_perl_cfg() { sed -n "s/^$1='\(.*\)'\$/\1/p" "${TARGET_PERL_CONFIG}" | head -n1; }

TARGET_PERL_VERSION="$(target_perl_cfg version)"      # e.g. 5.44.0
TARGET_PERL_CCFLAGS="$(target_perl_cfg ccflags)"
# polymake encodes the perl version as the dotless integer, matching
# write_perl_specific_configuration_file() in support/configure.pl
TARGET_PERL_VERSION_ID="${TARGET_PERL_VERSION//./}"   # e.g. 5440

# Statically linked perl extensions.
#
# A perl without dynamic loading keeps POSIX, Storable, List::Util, IO, Encode
# and the rest as separate archives under archlib/auto/, not inside libperl.a,
# and nothing loads them at runtime.  They have to be linked in *and* registered
# from xs_init, which patch 0007 does from this list; without it the interpreter
# starts and then dies on the first `use POSIX`.
#
# The list is derived from the archives that are actually present rather than
# from $Config{static_ext}, because the two do not quite agree -- Devel::PPPort
# is listed but installs no archive -- and the filesystem is the side that
# decides what can be linked.  auto/List/Util/Util.a yields "List/Util", which is
# the notation $Config{static_ext} and hence createBootstrap.pl expects.
POLYMAKE_PERL_STATIC_EXT="$(cd "${TARGET_PERL_ARCHLIB}/auto" && find . -name '*.a' | sed -E 's|^\./||; s|/[^/]+\.a$||' | sort -u | tr '\n' ' ')"
export POLYMAKE_PERL_STATIC_EXT
test -n "${POLYMAKE_PERL_STATIC_EXT}"

PERL_EXT_ARCHIVES=()
while IFS= read -r a; do
    PERL_EXT_ARCHIVES+=("$a")
done < <(find "${TARGET_PERL_ARCHLIB}/auto" -name '*.a' | sort)
test "${#PERL_EXT_ARCHIVES[@]}" -gt 0

# --------------------------------------------------------------------------
# compiler and linker flags
# --------------------------------------------------------------------------

# -fwasm-exceptions: polymake propagates errors out of the C++ core into the
# perl interpreter with real C++ exceptions, and the callable API throws.  This
# also matches the exception model the ppl package in this channel is built with.
EM_ARCH_FLAGS="-fwasm-exceptions -sSUPPORT_LONGJMP=wasm"

POLYMAKE_CXXFLAGS="$(strip_arch "${CXXFLAGS:-}") ${EM_ARCH_FLAGS} -I${PREFIX}/include -I${PREFIX}/include/flint -I${PREFIX}/include/cddlib -I${PREFIX}/include/singular"
POLYMAKE_CFLAGS="$(strip_arch "${CFLAGS:-}") ${EM_ARCH_FLAGS} -I${PREFIX}/include"
POLYMAKE_LDFLAGS="-L${PREFIX}/lib ${EM_ARCH_FLAGS}"

# Emscripten settings for the final executable.  polymake keeps large rule and
# type databases in memory and recurses deeply through its C++/perl glue, so it
# needs considerably more than the emscripten defaults.
EM_LINK_FLAGS=(
  -O2
  ${EM_ARCH_FLAGS}
  -sALLOW_MEMORY_GROWTH=1
  -sINITIAL_MEMORY=512MB
  -sMAXIMUM_MEMORY=4GB
  -sSTACK_SIZE=32MB
  -sFORCE_FILESYSTEM=1
  # main() runs on startup, which is what the node launcher wants; keeping the
  # runtime alive afterwards is what lets an embedder go on calling the exported
  # polymake_* functions once main has returned on end of input.
  -sEXIT_RUNTIME=0
  -sWASM_BIGINT
  -sEXPORTED_RUNTIME_METHODS=callMain,ccall,cwrap,FS,ENV
  -sEXPORTED_FUNCTIONS=_main,_polymake_init,_polymake_execute,_polymake_last_stdout,_polymake_last_stderr,_polymake_last_error,_polymake_greeting
  -Wl,--allow-multiple-definition
)

# --------------------------------------------------------------------------
# configure
# --------------------------------------------------------------------------

# Bundled extensions: everything whose library is packaged in this channel is
# enabled and pointed at ${PREFIX}.  java/javaview/jreality need a JDK, polydb
# needs mongoc, and scip/soplex/sympol are left off to keep the first port's
# link surface small -- all of them can be switched on the same way.
./configure \
    PERL="${BUILD_PERL}" \
    CC="emcc" \
    CXX="em++" \
    Arch="wasm32" \
    CFLAGS="${POLYMAKE_CFLAGS}" \
    CXXFLAGS="${POLYMAKE_CXXFLAGS}" \
    LDFLAGS="${POLYMAKE_LDFLAGS}" \
    --prefix="${PREFIX}" \
    --without-prereq \
    --without-native \
    --without-openmp \
    --with-gmp="${PREFIX}" \
    --with-mpfr="${PREFIX}" \
    --with-boost="${PREFIX}" \
    --with-permlib=bundled \
    --with-bliss="${PREFIX}" \
    --with-cdd="${PREFIX}" \
    --with-flint="${PREFIX}" \
    --with-lrs="${PREFIX}" \
    --with-libnormaliz="${PREFIX}" \
    --with-nauty="${PREFIX}" \
    --with-ppl="${PREFIX}" \
    --with-singular="${PREFIX}" \
    --without-java \
    --without-javaview \
    --without-polydb \
    --without-scip \
    --without-soplex \
    --without-sympol

# --------------------------------------------------------------------------
# retarget the generated configuration
# --------------------------------------------------------------------------

# configure.pl derives the archiver from the perl that ran it; ${AR} is what the
# patched sharedmod rule uses, and only emar understands wasm objects.
sed -i "s|^AR *=.*|AR = emar|" build/config.ninja

# The perl-specific configuration is the one file that describes the interpreter
# polymake compiles against.  configure.pl filled it in from the *native* perl,
# because that is the perl it was running under; point every entry at the
# emscripten perl instead.  PERL and the xsubpp/typemap paths stay native: those
# are build-time tools, executed on the build machine, not linked into the target.
PERLX_CONFIG="$(ls build/perlx/*/*/config.ninja | head -n1)"
test -f "${PERLX_CONFIG}"

cat > "${PERLX_CONFIG}" <<EOF
PERL=${BUILD_PERL}
CXXglueFLAGS=-I${TARGET_PERL_CORE} ${TARGET_PERL_CCFLAGS} -DPerlVersion=${TARGET_PERL_VERSION_ID} -Wno-nonnull -Wno-xor-used-as-pow
LIBperlFLAGS=-L${TARGET_PERL_CORE} -lperl
ExtUtils_xsubpp=$("${BUILD_PERL}" -MConfig -e 'print "$Config{privlib}/ExtUtils/xsubpp"')
ExtUtils_typemap=${TARGET_PERL_PRIVLIB}/ExtUtils/typemap
EOF

test -f "${TARGET_PERL_PRIVLIB}/ExtUtils/typemap"

# Read back what configure decided rather than reconstructing it here.
ninja_var() { sed -n "s|^ *$1 *= *||p" build/config.ninja | head -n1; }

INSTALL_TOP="$(ninja_var InstallTop)"
INSTALL_ARCH="$(ninja_var InstallArch)"
test -n "${INSTALL_TOP}"
test -n "${INSTALL_ARCH}"

# --------------------------------------------------------------------------
# build and install
# --------------------------------------------------------------------------

ninja -C build/Opt -j"${CPU_COUNT:-2}" all
# the perl-independent core archive is not part of `all`; it is what a consumer
# of the callable library links against together with libpolymake.a
ninja -C build/Opt -j"${CPU_COUNT:-2}" all.corelib
ninja -C build/Opt install

test -d "${INSTALL_TOP}/perllib"
test -d "${INSTALL_ARCH}/lib"

# --------------------------------------------------------------------------
# final link
# --------------------------------------------------------------------------

# Harvest the library flags configure worked out, including the per-extension
# ones it recorded for the bundled extensions, rather than hardcoding them here.
TOP_LIBS="$(ninja_var LIBS)"
BUNDLED_LIBS="$(sed -n 's|^bundled\.[a-z0-9_]*\.LIBS *= *||p' build/config.ninja | tr '\n' ' ')"
BUNDLED_LDFLAGS="$(sed -n 's|^bundled\.[a-z0-9_]*\.LDFLAGS *= *||p' build/config.ninja | tr '\n' ' ')"

# -ldl and -lpthread are meaningless for a single-threaded static wasm binary and
# make emcc complain; everything else configure found is passed through.
TOP_LIBS="$(echo "${TOP_LIBS}" | sed -E 's/(^| )-l(dl|pthread)( |$)/ /g')"

# Application archives.  Applications without any C++ client code get an empty
# placeholder file from the `emptyfile` rule, which is not an archive.
APP_ARCHIVES=()
for a in "${INSTALL_ARCH}"/lib/*; do
    case "$(basename "$a")" in
        # the fake/stub application libraries exist only so that the callable
        # library can link without the real applications; here the real ones are
        # present and these would collide with them
        libpolymake-apps*) continue ;;
    esac
    [ -s "$a" ] || continue
    APP_ARCHIVES+=("$a")
done
test "${#APP_ARCHIVES[@]}" -gt 0

# The callable library archive carries the core, the perl glue and xs_init.
CALLABLE_ARCHIVE=""
for c in "${PREFIX}"/lib/libpolymake.*; do
    [ -f "$c" ] && [ ! -L "$c" ] || continue
    case "$c" in *-apps*) continue ;; esac
    CALLABLE_ARCHIVE="$c"
    break
done
test -n "${CALLABLE_ARCHIVE}"

em++ -c "${RECIPE_DIR}/polymake_wasm_main.cc" -o polymake_wasm_main.o \
    -std=c++14 -DPOLYMAKE_DEBUG=0 \
    ${POLYMAKE_CXXFLAGS} \
    -I"${PREFIX}/include"

mkdir -p "${PREFIX}/bin"

# --whole-archive is not an optimization here: polymake registers every client
# function, type and rule from static constructors, so an archive member that
# resolves no undefined symbol would be dropped and its registrations lost.
#
# Order matters for the two archive groups that follow it: the perl extension
# archives are pulled in by the boot_* references in the generated xs_init and in
# turn need the perl API, so they have to precede libperl.a.
em++ -o "${PREFIX}/bin/polymake.js" \
    polymake_wasm_main.o \
    -Wl,--whole-archive \
    "${APP_ARCHIVES[@]}" \
    "${CALLABLE_ARCHIVE}" \
    -Wl,--no-whole-archive \
    "${PERL_EXT_ARCHIVES[@]}" \
    "${TARGET_PERL_CORE}/libperl.a" \
    -L"${PREFIX}/lib" \
    ${BUNDLED_LDFLAGS} \
    ${BUNDLED_LIBS} \
    ${TOP_LIBS} \
    "${EM_LINK_FLAGS[@]}"

test -f "${PREFIX}/bin/polymake.wasm"

# --------------------------------------------------------------------------
# filesystem image
# --------------------------------------------------------------------------

# The wasm runtime sees none of the host filesystem, so everything polymake and
# perl read at runtime is packed into polymake.data.  The mount points match the
# defaults compiled into polymake_wasm_main.cc.
#
# The `shared` symlink the installer drops next to the architecture-dependent
# tree points back at the top tree; following it here would pack the whole rule
# set a second time.  polymake_wasm_main.cc passes both directories explicitly,
# so the symlink is not needed inside the image.
rm -f "${INSTALL_ARCH}/shared"

# The archives are build inputs, already linked into polymake.wasm above, and the
# patched loader never looks for them again.
rm -f "${INSTALL_ARCH}"/lib/*
rm -rf "${INSTALL_ARCH}/perlx"

python3 "${EMSCRIPTEN_DIR}/tools/file_packager.py" \
    "${PREFIX}/bin/polymake.data" \
    --preload "${INSTALL_TOP}@/polymake/share" \
    --preload "${INSTALL_ARCH}@/polymake/lib" \
    --preload "${PREFIX}/lib/perl5@/polymake/perl5" \
    --exclude '*/pod/*' '*.pod' '*/demo/*' \
    --js-output="${PREFIX}/bin/polymake.data.js"

test -f "${PREFIX}/bin/polymake.data"

# --------------------------------------------------------------------------
# tidy up the installed tree
# --------------------------------------------------------------------------

# The build system names the callable library after the platform's shared library
# convention -- libpolymake.so.<version> plus a libpolymake.so symlink -- but the
# patched sharedmod rule made it an ar archive.  Give it the name and extension a
# consumer would actually link against, and drop the now meaningless symlink and
# the fake/stub application libraries.
if [ "${CALLABLE_ARCHIVE}" != "${PREFIX}/lib/libpolymake.a" ]; then
    mv "${CALLABLE_ARCHIVE}" "${PREFIX}/lib/libpolymake.a"
fi
find "${PREFIX}/lib" -maxdepth 1 \( -name 'libpolymake.so*' -o -name 'libpolymake-apps*' \) -delete

test -f "${PREFIX}/lib/libpolymake.a"
test -f "${PREFIX}/lib/libpolymake-core.a" || cp build/Opt/lib/libpolymake-core.a "${PREFIX}/lib/"
test -f "${PREFIX}/lib/libpolymake-core.a"

# a small launcher so that `polymake` works from the command line in a node env
cat > "${PREFIX}/bin/polymake" <<'EOF'
#!/usr/bin/env bash
here="$(cd "$(dirname "$0")" && pwd)"
exec node "${here}/polymake.js" "$@"
EOF
chmod 755 "${PREFIX}/bin/polymake"

LICENSE_DIR="${PREFIX}/share/licenses/${PKG_NAME}"
mkdir -p "${LICENSE_DIR}"
install -Dm644 "${SRC_DIR}/COPYING" "${LICENSE_DIR}/COPYING"

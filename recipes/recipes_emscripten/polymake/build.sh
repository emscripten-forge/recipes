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
# for gmp, mpfr, flint, bliss, ppl, cddlib, lrslib and normaliz actually run
# instead of failing as "cannot execute binary file".
export POLYMAKE_TEST_RUNNER="node"
export POLYMAKE_TEST_SUFFIX=".js"
# Link flags for the test programs only (never recorded for the real build).
# Emscripten does not flush stdio at exit by default, so a probe that prints
# without a trailing newline -- the ppl version check -- yields no output, only a
# warning on stderr, which then reaches polymake's version comparison and breaks
# its eval ("Number found where operator expected ... near 'to 1'", the 'to 1'
# coming from "set EXIT_RUNTIME to 1" in that warning).
export POLYMAKE_TEST_LDFLAGS="-sEXIT_RUNTIME=1 -sALLOW_MEMORY_GROWTH=1"

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

# Transitive dependencies of static archives.  A shared libflint.so records a
# DT_NEEDED entry for libmpfr, and libppl.so one for libgmpxx, so natively the
# loader pulls them in and nobody names them.  Static archives carry no such
# records: every transitive dependency has to appear on the link line.  polymake's
# probes name only the direct library (-lflint, -lppl), and fail with
# "libflint.a(arf_merged.o): undefined symbol: mpfr_sqr" and
# "libppl.a: undefined symbol: operator<<(std::ostream&, __mpz_struct const*)".
# configure appends LIBS to every test program, and wasm-ld resolves archives
# regardless of their position on the line, so naming them once here suffices.
#
# libsingular needs the same treatment, and more of it: libsingular-config --libs
# names only -lSingular -lpolys -lsingular_resources -lfactory -lomalloc, and
# `pkg-config --static` adds just NTL, but libSingular.a also pulls in cddlib and
# mathicgb/mathic/memtailor.  Linking polymake's singular probe against the
# channel's packages is how this list was established.
#
# polymake_wasm_stubs.o supplies the POSIX named-semaphore functions that
# libSingular.a references and emscripten does not implement, and sets Singular's
# resource environment.  It is an object file rather than a library so that it is
# always pulled in; configure appends LIBS to every test program, which is what
# gets it into the singular probe as well as the final link.
POLYMAKE_EXTRA_LIBS="${SRC_DIR}/polymake_wasm_stubs.o -lntl -lcddgmp -lmathicgb -lmathic -lmemtailor -lgmpxx -lmpfr -lgmp"

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
# emscripten stubs
# --------------------------------------------------------------------------

# Built before configure, because the singular probe links against it.
# POLYMAKE_WASM_SINGULAR_DIR must match where the filesystem image below mounts
# the singular package's share/singular directory.
emcc -c "${RECIPE_DIR}/polymake_wasm_stubs.c" -o "${SRC_DIR}/polymake_wasm_stubs.o" \
    -DPOLYMAKE_WASM_SINGULAR_DIR='"/polymake/singular"'
test -f "${SRC_DIR}/polymake_wasm_stubs.o"

# --------------------------------------------------------------------------
# configure
# --------------------------------------------------------------------------

# Bundled extensions: everything whose library is packaged in this channel is
# enabled and pointed at ${PREFIX}, with these exceptions:
#
#  - nauty: polymake declares it CONFLICT with bliss (bundled/nauty/polymake.ext);
#    both are alternative backends for graph_compare and only one may be enabled.
#    bliss is kept.  The nauty *package* is still a host dependency, because
#    normaliz links against it.
#  - singular: enabled, but it needs more than a --with flag; see the LIBS
#    comment above, polymake_wasm_stubs.c, and patch 0011.  The singular package
#    itself is not modified.
#  - java/javaview need a JDK, polydb needs mongoc (not in the channel), and
#    scip/soplex/sympol are left off to keep the first port's link surface small.
./configure \
    PERL="${BUILD_PERL}" \
    CC="emcc" \
    CXX="em++" \
    Arch="wasm32" \
    CFLAGS="${POLYMAKE_CFLAGS}" \
    CXXFLAGS="${POLYMAKE_CXXFLAGS}" \
    LDFLAGS="${POLYMAKE_LDFLAGS}" \
    LIBS="${POLYMAKE_EXTRA_LIBS}" \
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
    --without-nauty \
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

# ExtUtils::xsubpp turns the .xxs sources into C++.  It runs here, on the build
# machine, so it has to be the build perl's own copy -- but $Config{privlib} is the
# wrong way to find it.  A relocatable perl, which is what conda ships, keeps the
# prefix it was *configured* with in Config and fixes @INC up at run time instead, so
# the recorded path need not exist:
#
#   Can't open perl script ".../../lib/perl5/core_perl/ExtUtils/xsubpp"
#
# @INC is the list that is right, and xsubpp is installed next to the ExtUtils
# modules, so look for it there.
ExtUtils_xsubpp="$("${BUILD_PERL}" -e 'for (@INC) { my $p = "$_/ExtUtils/xsubpp"; if (-f $p) { print $p; last } }')"
if [ ! -f "${ExtUtils_xsubpp}" ]; then
    ExtUtils_xsubpp="$(find "${BUILD_PREFIX}/lib" -type f -name xsubpp 2>/dev/null | head -n1)"
fi
# fail here rather than a few hundred ninja steps later
test -f "${ExtUtils_xsubpp}"

# The perl-specific configuration is the one file that describes the interpreter
# polymake compiles against.  configure.pl filled it in from the *native* perl,
# because that is the perl it was running under; point every entry at the
# emscripten perl instead.  PERL and xsubpp stay native -- they are build-time
# tools, executed here, not linked into the target -- while the typemap comes from
# the target perl, because it is data describing the interpreter the generated glue
# is compiled against.
PERLX_CONFIG="$(ls build/perlx/*/*/config.ninja | head -n1)"
test -f "${PERLX_CONFIG}"
test -f "${TARGET_PERL_PRIVLIB}/ExtUtils/typemap"

cat > "${PERLX_CONFIG}" <<EOF
PERL=${BUILD_PERL}
CXXglueFLAGS=-I${TARGET_PERL_CORE} ${TARGET_PERL_CCFLAGS} -DPerlVersion=${TARGET_PERL_VERSION_ID} -Wno-nonnull -Wno-xor-used-as-pow
LIBperlFLAGS=-L${TARGET_PERL_CORE} -lperl
ExtUtils_xsubpp=${ExtUtils_xsubpp}
ExtUtils_typemap=${TARGET_PERL_PRIVLIB}/ExtUtils/typemap
EOF

# Read back what configure decided rather than reconstructing it here.
ninja_var() { sed -n "s|^ *$1 *= *||p" build/config.ninja | head -n1; }

INSTALL_TOP="$(ninja_var InstallTop)"
INSTALL_ARCH="$(ninja_var InstallArch)"
test -n "${INSTALL_TOP}"
test -n "${INSTALL_ARCH}"

# --------------------------------------------------------------------------
# build and install
# --------------------------------------------------------------------------

# Keep ninja from re-running configure on this first build (see patch 0009): the
# rerun would fail on --without-polydb and, worse, regenerate both config.ninja
# files from the native perl, undoing the retargeting done above.
export POLYMAKE_NO_RECONFIGURE=1

# ${PREFIX}/include comes before polymake's own include directories on every compile
# command, because it is part of CXXFLAGS and the build system appends its own paths
# after it.  `ninja install` copies polymake's headers into ${PREFIX}/include/polymake,
# so any compile after an install would silently read the installed copies instead of
# the sources -- which, in a rebuild, are the ones that just changed.  A clean build
# never has them, but removing them costs nothing and makes rebuilding this recipe in
# place behave the way anyone would expect.
rm -rf "${PREFIX}/include/polymake"

# support/generate_applib_fake.pl lists the public symbols of every application
# module to build the stub library that ships beside the callable library.  It runs
# on the build machine, but the modules are wasm archives, so the system nm cannot
# read them; patch 0014 lets NM name the symbol lister to use instead.  em-config
# reports where the toolchain's llvm binaries live.
NM="$(em-config LLVM_ROOT)/llvm-nm"
test -x "${NM}" || NM="$(command -v llvm-nm)"
test -x "${NM}"
export NM

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

# Move them aside.  They are build inputs -- already linked into polymake.wasm by
# the time anything runs -- and the patched module loader never looks for them
# again, so they must not end up in the filesystem image, which is built first
# now that the link needs its loader script.
LINK_STAGE="${SRC_DIR}/link-stage"
rm -rf "${LINK_STAGE}"
mkdir -p "${LINK_STAGE}"
for i in "${!APP_ARCHIVES[@]}"; do
    mv "${APP_ARCHIVES[$i]}" "${LINK_STAGE}/"
    APP_ARCHIVES[$i]="${LINK_STAGE}/$(basename "${APP_ARCHIVES[$i]}")"
done

# The callable library archive carries the core, the perl glue and xs_init.
CALLABLE_ARCHIVE=""
for c in "${PREFIX}"/lib/libpolymake.*; do
    [ -f "$c" ] && [ ! -L "$c" ] || continue
    case "$c" in *-apps*) continue ;; esac
    CALLABLE_ARCHIVE="$c"
    break
done
test -n "${CALLABLE_ARCHIVE}"

# --------------------------------------------------------------------------
# filesystem image
# --------------------------------------------------------------------------

# The wasm runtime sees none of the host filesystem, so everything polymake and
# perl read at runtime is packed into polymake.data.  The mount points match the
# defaults compiled into polymake_wasm_main.cc.  It is built before the final link,
# because file_packager writes the loader that mounts it as a separate script and the
# link has to embed that script with --pre-js; nothing loads it otherwise.
#
# The *.a exclusion drops perl's own static extension archives under archlib/auto and
# CORE/libperl.a, roughly 14MB.  They are linked into polymake.wasm and a running perl
# never reads them, since this interpreter has no dynamic loading to begin with.
#
# The `shared` symlink the installer drops next to the architecture-dependent
# tree points back at the top tree; following it here would pack the whole rule
# set a second time.  polymake_wasm_main.cc passes both directories explicitly,
# so the symlink is not needed inside the image.
rm -f "${INSTALL_ARCH}/shared"

# The application archives were moved to ${LINK_STAGE} above; whatever is left here
# is the fake/stub application libraries, which exist only so that the callable
# library can be linked without the real applications.  The perlx tree holds only the
# callable library under its shared-object name, which the link takes from
# ${PREFIX}/lib instead.
rm -f "${INSTALL_ARCH}"/lib/*
rm -rf "${INSTALL_ARCH}/perlx"

python3 "${EMSCRIPTEN_DIR}/tools/file_packager.py" \
    "${PREFIX}/bin/polymake.data" \
    --preload "${INSTALL_TOP}@/polymake/share" \
    --preload "${INSTALL_ARCH}@/polymake/lib" \
    --preload "${PREFIX}/lib/perl5@/polymake/perl5" \
    --preload "${PREFIX}/share/singular@/polymake/singular" \
    --exclude '*/pod/*' '*.pod' '*/demo/*' '*.a' \
    --js-output="${PREFIX}/bin/polymake.data.js"

test -f "${PREFIX}/bin/polymake.data"

# The perl library tree is mounted at /polymake/perl5, so the search path the driver
# installs is the target perl's own library directories with their ${PREFIX}/lib/perl5
# prefix rewritten, in perl's usual order.  All of them are needed and none is
# guessable, which is why they are read from the perl package's own Config rather than
# assembled here: this perl keeps lib.pm, Config.pm and the extension stubs in the
# versioned architecture-dependent directory, the rest of the core library in the
# unversioned one, and the CPAN modules polymake requires -- JSON above all, which it
# loads while starting up -- under site_perl.
WASM_PERL5LIB=""
perl_json_reachable=""
for perl_libdir in "$(target_perl_cfg sitearch)" "$(target_perl_cfg sitelib)" \
                   "${TARGET_PERL_ARCHLIB}" "${TARGET_PERL_PRIVLIB}"; do
    # only directories inside the tree that goes into the image are reachable there
    case "${perl_libdir}" in
        "${PREFIX}/lib/perl5/"*) ;;
        *) continue ;;
    esac
    [ -f "${perl_libdir}/JSON.pm" ] && perl_json_reachable=1
    WASM_PERL5LIB="${WASM_PERL5LIB}${WASM_PERL5LIB:+:}/polymake/perl5/${perl_libdir#${PREFIX}/lib/perl5/}"
done
test -n "${WASM_PERL5LIB}"

# polymake loads JSON while starting up.  A search path that misses it yields a
# binary which builds cleanly and then dies on its first run, so check it here
# instead -- the perl package keeps JSON under site_perl, which is reached only
# because the loop above reads the directories out of that package's own Config.
test -n "${perl_json_reachable}"

em++ -c "${RECIPE_DIR}/polymake_wasm_main.cc" -o polymake_wasm_main.o \
    -std=c++14 -DPOLYMAKE_DEBUG=0 \
    -DPOLYMAKE_WASM_PERL5LIB="\"${WASM_PERL5LIB}\"" \
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
    --pre-js "${PREFIX}/bin/polymake.data.js" \
    "${EM_LINK_FLAGS[@]}"

test -f "${PREFIX}/bin/polymake.wasm"

rm -rf "${LINK_STAGE}"


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

# A small launcher so that `polymake` works from the command line in a node env.
# polymake's installer has already put its own launcher at this path -- a perl script
# expecting a native interpreter, which does not exist in this build -- and it copies
# with mode 0555 (support/install.pl).  Remove it before writing: overwriting a
# read-only file succeeds for root, which is why a local build never notices, and
# fails with EACCES for every other user, which is what a CI build runs as.
rm -f "${PREFIX}/bin/polymake"
cat > "${PREFIX}/bin/polymake" <<'EOF'
#!/usr/bin/env bash
here="$(cd "$(dirname "$0")" && pwd)"
exec node "${here}/polymake.js" "$@"
EOF
chmod 755 "${PREFIX}/bin/polymake"

LICENSE_DIR="${PREFIX}/share/licenses/${PKG_NAME}"
mkdir -p "${LICENSE_DIR}"
install -Dm644 "${SRC_DIR}/COPYING" "${LICENSE_DIR}/COPYING"

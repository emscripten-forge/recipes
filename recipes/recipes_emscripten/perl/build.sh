#!/bin/bash
set -euo pipefail

cd "${SRC_DIR}"

HOST_DIR="${BUILD_DIR}/host-tools"
HOST_PREFIX="${BUILD_DIR}/host-install"
INSTALL_DIR="${BUILD_DIR}/install"

rm -rf \
    "${HOST_DIR}" \
    "${HOST_PREFIX}" \
    "${INSTALL_DIR}"

mkdir -p \
    "${HOST_DIR}" \
    "${HOST_PREFIX}" \
    "${INSTALL_DIR}"

# Native build toolchain

HOST_CC="${CC_FOR_BUILD:-gcc}"
HOST_CXX="${CXX_FOR_BUILD:-g++}"
HOST_AR="${AR_FOR_BUILD:-ar}"
HOST_RANLIB="${RANLIB_FOR_BUILD:-ranlib}"

# Build native host Perl

echo "==> Configuring native Perl"

CC="${HOST_CC}" \
CXX="${HOST_CXX}" \
AR="${HOST_AR}" \
RANLIB="${HOST_RANLIB}" \
./Configure \
    -des \
    -Dprefix="${HOST_PREFIX}" \
    -Dman1dir=none \
    -Dman3dir=none \
    -Duseshrplib=false \
    -Dusemymalloc=n \
    -Dmyhostname=localhost \
    -Dmydomain=.local \
    -Dperladmin=root@localhost

CC="${HOST_CC}" \
CXX="${HOST_CXX}" \
AR="${HOST_AR}" \
RANLIB="${HOST_RANLIB}" \
make -j"${CPU_COUNT:-2}" miniperl generate_uudmap

test -x miniperl
test -x generate_uudmap

# Preserve the native tools.
# They must survive the distclean before the Emscripten build.

cp miniperl "${HOST_DIR}/miniperl"
cp generate_uudmap "${HOST_DIR}/generate_uudmap"

chmod 755 \
    "${HOST_DIR}/miniperl" \
    "${HOST_DIR}/generate_uudmap"

echo "==> Host Perl version"
"${HOST_DIR}/miniperl" -e 'print "$^V\n"'

# Clean the source tree before switching compilers

make distclean

# Create Emscripten hint file

cat > hints/emscripten.sh <<'EOF'
#!/bin/sh

###############################################################################
# Perl 5.44.0 / Emscripten / WebAssembly
###############################################################################

osname='emscripten'
archname='wasm'
osvers='emscripten'

myhostname='localhost'
mydomain='.local'
perladmin='root@localhost'

###############################################################################
# Toolchain
###############################################################################

cc='emcc'
ld='emcc'
ar='emar'
ranlib='emranlib'

###############################################################################
# Filesystem
###############################################################################

lns='/bin/ln'

###############################################################################
# Do not search host libraries.
#
# The target sysroot is passed explicitly from build.sh.
###############################################################################

loclibpth=''
glibpth=''

###############################################################################
# Static Perl
###############################################################################

dynamic_ext=''
usemymalloc='n'
useshrplib='false'
uselargefiles='n'

###############################################################################
# Skip the C library nm-symbol-scan.
#
# Configure's "Figure out where the libc is located" block (searching
# glibpth/loclibpth, then falling back to an interactive "Where is your
# C library?" prompt) is gated entirely on usenm being true. With
# loclibpth/glibpth empty above, that search always fails, and under
# -des (non-interactive) it loops on an empty default until it gives
# up and aborts the whole build.
#
# There is nothing for that scan to find anyway: Emscripten's libc is
# synthesized on demand by emcc (cached under ~/.emscripten_cache), not
# a host libc.a for the host's nm to inspect. Disabling usenm skips the
# scan entirely and falls back to trial compilation for symbol checks,
# same as darwin.sh, interix.sh, dragonfly.sh, os390.sh, and other
# hints for platforms without a conventional host-style libc.
###############################################################################

usenm='false'

###############################################################################
# WASM32
###############################################################################

selectminbits='32'
alignbytes='4'

###############################################################################
# Dynamic loading is unavailable in the browser runtime.
###############################################################################

dlsrc='none'
d_dlopen='undef'

###############################################################################
# Unix process APIs unavailable in browser WASM.
###############################################################################

d_fork='undef'
d_vfork='undef'
d_waitpid='undef'
d_wait4='undef'
d_pseudofork='undef'

d_procselfexe='undef'
d_setproctitle='undef'

d_setruid='undef'
d_setrgid='undef'
d_seteuid='undef'
d_setegid='undef'

###############################################################################
# No pthreads for the baseline WebPerl build.
###############################################################################

i_pthread='undef'
d_pthread_atfork='undef'
d_pthread_yield='undef'
d_pthread_attr_setscope='undef'

###############################################################################
# Miscellaneous unavailable libc APIs.
###############################################################################

d_malloc_size='undef'
d_malloc_good_size='undef'
d_fdclose='undef'
d_shm='undef'

###############################################################################
# Compiler flags
###############################################################################

ccflags="$ccflags -D_GNU_SOURCE"
ccflags="$ccflags -D_POSIX_C_SOURCE=200809L"
ccflags="$ccflags -DNO_MATHOMS"
ccflags="$ccflags -fno-strict-aliasing"

###############################################################################
# Silence -Wimplicit-void-ptr-cast.
#
# Newer Clang (as bundled by this Emscripten release) warns on ordinary,
# valid C idioms like "return NULL;" from a typed-pointer function,
# because that implicit void*-to-T* conversion would be illegal in C++.
# This is a portability note, not a bug in Perl's C sources, but at
# hundreds of hits per file it drowns out real errors in the build log.
###############################################################################

ccflags="$ccflags -Wno-implicit-void-ptr-cast"

cppflags="$cppflags -D_GNU_SOURCE"
cppflags="$cppflags -D_POSIX_C_SOURCE=200809L"
cppflags="$cppflags -DNO_MATHOMS"
cppflags="$cppflags -fno-strict-aliasing"

###############################################################################
# Linker flags
#
# Keep these minimal while getting Perl 5.44 cross compilation working.
###############################################################################

ldflags="$ldflags -O2"

libs="$libs -lm"
EOF

chmod 644 hints/emscripten.sh

export CC=emcc
export CXX=em++
export AR=emar
export RANLIB=emranlib

# Locate the actual Emscripten installation.

if [ -n "${EMSCRIPTEN:-}" ]; then
    EMSCRIPTEN_ROOT="${EMSCRIPTEN}"
else
    EMSCRIPTEN_ROOT="${BUILD_PREFIX}/opt/emsdk/upstream/emscripten"
fi

export EMSCRIPTEN="${EMSCRIPTEN_ROOT}"

EMSCRIPTEN_SYSROOT="${EMSCRIPTEN_ROOT}/system"

test -d "${EMSCRIPTEN_ROOT}"
test -d "${EMSCRIPTEN_SYSROOT}"

echo "==> Emscripten root: ${EMSCRIPTEN_ROOT}"
echo "==> Emscripten sysroot: ${EMSCRIPTEN_SYSROOT}"

echo "==> Emscripten toolchain"

command -v "${CC}"
command -v "${CXX}"
command -v "${AR}"
command -v "${RANLIB}"

"${CC}" --version

# Configure Perl for Emscripten

emconfigure ./Configure \
    -des \
    -Dhintfile=emscripten \
    -Dsysroot="${EMSCRIPTEN_SYSROOT}" \
    -Dhostperl="${HOST_DIR}/miniperl" \
    -Dhostgenerate="${HOST_DIR}/generate_uudmap" \
    -Dprefix="${PREFIX}" \
    -Dman1dir=none \
    -Dman3dir=none \
    -Duseshrplib=false \
    -Dusemymalloc=n \
    -Duselargefiles=n \
    -Dmyhostname=localhost \
    -Dmydomain=.local \
    -Dperladmin=root@localhost \
    -Dlns=/bin/ln 
    
# Build target Perl

emmake make -j"${CPU_COUNT:-2}" perl

test -f perl
chmod 755 perl

# Install using the native host miniperl

"${HOST_DIR}/miniperl" \
    installperl \
    "--destdir=${INSTALL_DIR}"

# Install Perl libraries

if [ -d "${INSTALL_DIR}${PREFIX}/lib" ]; then
    mkdir -p "${PREFIX}/lib"

    cp -a \
        "${INSTALL_DIR}${PREFIX}/lib/." \
        "${PREFIX}/lib/"
fi

# Install Emscripten executable

mkdir -p "${PREFIX}/bin"

if [ -f perl.js ]; then
    install -Dm755 \
        perl.js \
        "${PREFIX}/bin/perl.js"

    install -Dm755 \
        perl.js \
        "${PREFIX}/bin/perl"
else
    install -Dm755 \
        perl \
        "${PREFIX}/bin/perl"
fi

if [ -f perl.wasm ]; then
    install -Dm644 \
        perl.wasm \
        "${PREFIX}/bin/perl.wasm"
fi

# Licenses

LICENSE_DIR="${PREFIX}/share/licenses/${PKG_NAME}"

mkdir -p "${LICENSE_DIR}"

install -Dm644 \
    "${SRC_DIR}/Artistic" \
    "${LICENSE_DIR}/Artistic"

install -Dm644 \
    "${SRC_DIR}/Copying" \
    "${LICENSE_DIR}/Copying"

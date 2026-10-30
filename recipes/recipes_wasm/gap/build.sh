#!/usr/bin/env bash

set -eux

unset EXCEPTION_HANDLING_FLAGS
unset EMCC_CFLAGS
BASEDIR="$(pwd)"

if ! command -v emmake &> /dev/null; then
    echo Please install, and source, emscripten
    echo This script was tested with version 3.1.23
    echo See https://emscripten.org/docs/getting_started/downloads.html for install instructions
    exit 1
fi;

# Build the configure script if this is a fresh git checkout
if [[ ! -f ./configure ]]; then
    ./autogen.sh
fi

# First build a standard GAP install, for some files
# we will need during building
rm -f src/c_oper1.c src/c_type1.c src/ffdata.c src/ffdata.h
(
    mkdir -p native-build
    cd native-build
    if [[ ! -f config.status ]]; then
        # Isolate the native build from conda's emscripten environment variables
        export CC="${CC_FOR_BUILD:-gcc}"
        export CXX="${CXX_FOR_BUILD:-g++}"
        export CFLAGS=""
        export CXXFLAGS=""
        export LDFLAGS=""
        export CPPFLAGS=""
        
        ../configure
    fi
    make -j8
)

# There are two problems with building GAP
# 1) GAP builds some executables (ffgen and gap-nocomp), which it wants to
#    execute while building. We get these files from 'native-build'.
# 2) 'configure' gets confused by some of the LDFLAGS we need, so we have to pass
#     them in to 'make'
#
# These options are:
# -sASYNCIFY -- we don't care about ASYNC, but this forces the compiler to output
# all variables onto the stack, which is required for GASMAN
# Note we could use 'ALLOW_MEMORY_GROWTH', both we don't currently, we instead set
# a big memory window.
# -O2 : Some optimisation
# EXEEXT=.html -- this is actually a GAP makefile option, it lets us make the
# output 'gap.html', which makes emscripten output a html page we can load
# --pre-js lazy_fs.js : Prepend lazy_fs.js that is generated for lazy loading

# Run configure if we don't have a makefile, or someone configured this
# GAP for standard building (emscripten builds will use 'emcc')
if [[ "${target_platform}" == "emscripten-wasm64" ]]; then
    GAP_ABI=64
else
    GAP_ABI=32
fi

if [[ ! -f GNUmakefile ]] || ! grep '/emcc' GNUmakefile > /dev/null; then
    emconfigure ./configure --prefix="${PREFIX}" --host="${HOST}" ABI=${GAP_ABI} \
    --with-gmp=${PREFIX} \
    --with-zlib=${PREFIX} \
    LDFLAGS="-s ASYNCIFY=1 -O2"
fi;

# GAP unconditionally compiles/links with -pthread (only HPC-GAP uses threads).
# On emscripten this adds the atomics feature / shared memory, so drop it.
sed -i.bak 's/^PTHREAD_CFLAGS = .*/PTHREAD_CFLAGS =/' GNUmakefile
sed -i.bak 's/^PTHREAD_LIBS = .*/PTHREAD_LIBS =/' GNUmakefile
rm -f GNUmakefile.bak

# Target the Linux/Unix block to redefine shared lib extensions to static
sed -i.bak 's/SHLIB_EXT=\.so/SHLIB_EXT=.a/' Makefile.rules
sed -i.bak 's/LIBGAP_FULL = libgap$(SHLIB_EXT)\.$(SHLIB_MAJOR)/LIBGAP_FULL = libgap.a/' Makefile.rules

# Swap the dynamic linker command for the static archiver
sed -i.bak 's/.*$(QUIET_LINK)$(LINK) -o $@ $(LINK_SHLIB_FLAGS).*/\t$(QUIET_LINK)$(AR) rcs $@ $(OBJS)/' Makefile.rules

# Prevent a circular dependency from deleting the archive
sed -i.bak 's/libgap$(SHLIB_EXT): $(LIBGAP_FULL)/libgap_avoid_circular: $(LIBGAP_FULL)/' Makefile.rules

# Remove symlink creation from the install step
sed -i.bak '/ln -sf $(LIBGAP_FULL) $(DESTDIR)$(libdir)\/libgap$(SHLIB_EXT)/d' Makefile.rules
sed -i.bak '/$(INSTALL_NAME_TOOL) -id/d' Makefile.rules
rm -f Makefile.rules.bak

# Get full required packages
emmake make bootstrap-pkg-full

# Copy in files from native_build
cp native-build/build/c_*.c native-build/build/ffdata.* src/

# The EXEEXT is usually for windows, but here it lets us set GAP's extension,
# so emcc emits gap.js + gap.wasm (the html page comes from gap-web-assets;
# emitting gap.html would run emcc's html minifier, which is broken in emsdk 6x).
emmake make -j${CPU_COUNT} LDFLAGS="-lidbfs.js -lworkerfs.js -s ASYNCIFY=1 -sASYNCIFY_STACK_SIZE=16mb -sTOTAL_STACK=32mb -sINITIAL_MEMORY=2048mb -O2" EXEEXT=".js"
emmake make install-bin install-gaproot install-sysinfo install-headers install-libgap

mkdir -p "${PREFIX}/bin/gapwasm"

cp gap.js "$PREFIX/bin/gapwasm/"
cp gap.wasm "$PREFIX/bin/gapwasm/"

EMSCRIPTEN_DIR="$(dirname "$(readlink -f "$(command -v emcc)")")"
python3 "${EMSCRIPTEN_DIR}/tools/file_packager.py" \
  "${PREFIX}/bin/gapwasm/gap.data" \
  --preload "${SRC_DIR}/pkg@/pkg" \
  --preload "${SRC_DIR}/lib@/lib" \
  --preload "${SRC_DIR}/grp@/grp" \
  --preload "${SRC_DIR}/doc@/doc" \
  --preload "${SRC_DIR}/hpcgap@/hpcgap" \
  --separate-metadata \
  --js-output="${PREFIX}/bin/gapwasm/gap.data.js"

gzip -9 "${PREFIX}/bin/gapwasm/gap.data"
cp -a "$SRC_DIR"/web/* "$PREFIX/bin/gapwasm/"

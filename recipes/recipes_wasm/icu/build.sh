#!/bin/bash

# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/libtool/build-aux/config.* ./source

set -e

cd source

chmod +x configure install-sh

# Must build twice because some of the files are used in the build process (e.g. icupkg)
# 1. Regular build
# 2. Cross-compilation

EXTRA_OPTS=""

mkdir cross_build
pushd cross_build
CC=$(which gcc) CXX=$(which g++) AR= AS= LD= CFLAGS= CXXFLAGS= LDFLAGS= CPPFLAGS= ../configure \
    --build=${BUILD} \
    --host=${BUILD} \
    --disable-samples \
    --disable-extras \
    --disable-layout \
    --disable-tests

make -j${CPU_COUNT}
EXTRA_OPTS="$EXTRA_OPTS --with-cross-build=$PWD"
popd

# --with-data-packaging="static" fails, "files" and "archive" ok
emconfigure ./configure   \
    --prefix=${PREFIX}    \
    --build=${BUILD}      \
    --host=${HOST}        \
    --disable-samples     \
    --disable-extras      \
    --disable-layout      \
    --disable-tests       \
    --disable-shared      \
    --enable-static       \
    --with-data-packaging="archive" \
    ${EXTRA_OPTS}

make -j${CPU_COUNT}
make install

# Copy .wasm files as well
cp ./bin/*.wasm $PREFIX/bin/
cp ./tools/icuinfo/icuinfo.wasm $PREFIX/bin

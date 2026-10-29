#!/bin/bash
set -ex

mkdir build
cd build
emcmake cmake ${CMAKE_ARGS} \
    -DBUILD_TESTING=OFF \
    -DBUILD_SHARED_LIBS=OFF \
    -DHIGHS_NO_DEFAULT_THREADS=ON \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_INSTALL_LIBDIR=lib \
    $SRC_DIR
emmake make -j${CPU_COUNT:-4} install

# CMake installs only the launcher; the wasm binary sits next to it
cp bin/highs.wasm $PREFIX/bin/ || true

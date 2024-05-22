#! /bin/bash

set -ex

mkdir -p build
cd build

emcmake cmake ${CMAKE_ARGS} \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_COLOR_MAKEFILE=OFF \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DBUILD_SHARED_LIBS=OFF \
  ..
make -j$CPU_COUNT VERBOSE=1
make install

# Copy the .wasm file also
cp gr2fonttest/gr2fonttest.wasm $PREFIX/bin

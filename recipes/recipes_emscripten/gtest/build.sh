#!/bin/bash
set -ex

# Build and install dynamic library
mkdir -p build
cd build

emcmake cmake ${CMAKE_ARGS} \
  -GNinja \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DCMAKE_CXX_STANDARD=17 \
  -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DCMAKE_BUILD_TYPE=Release \
  ..
ninja install

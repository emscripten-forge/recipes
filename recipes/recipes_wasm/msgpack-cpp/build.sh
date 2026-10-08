#!/bin/bash
set -e

mkdir -p build
cd build

emcmake cmake ${CMAKE_ARGS} \
  -GNinja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH=$PREFIX \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DMSGPACK_USE_BOOST=OFF \
  -DMSGPACK_BUILD_TESTS=OFF \
  -DMSGPACK_BUILD_EXAMPLES=OFF \
  ..

ninja install

#!/bin/bash
set -e

export CXXFLAGS="${CXXFLAGS} -fPIC"

mkdir -p build
cd build

emcmake cmake ${CMAKE_ARGS} .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_FIND_ROOT_PATH=$PREFIX \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DFETCH_DEPENDENCIES_WITH_CMAKE=OFF \
  -DBUILD_TESTS=OFF \
  -DBUILD_BENCHMARKS=OFF

emmake make -j${CPU_COUNT}
emmake make install

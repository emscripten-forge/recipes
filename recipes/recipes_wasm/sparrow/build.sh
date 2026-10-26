#!/bin/bash
set -e

# SPARROW_BUILD_SHARED is set per staging output in recipe.yaml (ON/OFF), so
# each output gets a CMake config that matches the library it ships.

export CXXFLAGS="${CXXFLAGS} -fPIC"

mkdir -p build
cd build

emcmake cmake ${CMAKE_ARGS} .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_FIND_ROOT_PATH=$PREFIX \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DUSE_DATE_POLYFILL=ON \
  -DSPARROW_BUILD_SHARED=${SPARROW_BUILD_SHARED} \
  -DBUILD_EXAMPLES=OFF \
  -DBUILD_TESTS=OFF \
  -DBUILD_DOCS=OFF

emmake make -j${CPU_COUNT}
emmake make install

#!/bin/bash
set -e

# SPARROW_IPC_BUILD_SHARED is set per staging output in recipe.yaml (ON/OFF),
# so each output gets a CMake config that matches the library it ships.

export CXXFLAGS="${CXXFLAGS} -fPIC"

mkdir -p build
cd build

emcmake cmake ${CMAKE_ARGS} .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_FIND_ROOT_PATH=$PREFIX \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DUSE_DATE_POLYFILL=ON \
  -Dflatbuffers_DIR=$PREFIX/lib/cmake/flatbuffers \
  -Dzstd_DIR=$PREFIX/lib/cmake/zstd \
  -DSPARROW_IPC_BUILD_SHARED=${SPARROW_IPC_BUILD_SHARED}

emmake make -j${CPU_COUNT}
emmake make install

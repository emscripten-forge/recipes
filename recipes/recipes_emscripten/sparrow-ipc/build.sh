#!/bin/bash
set -e

export CXXFLAGS="${CXXFLAGS} -fPIC"

# Create build directory
mkdir -p build
cd build

# Configure the build with CMake
emcmake cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_FIND_ROOT_PATH=$PREFIX \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DSPARROW_IPC_BUILD_SHARED=ON \
  -Dflatbuffers_DIR=$PREFIX/lib/cmake/flatbuffers \
  -DCMAKE_PROJECT_INCLUDE=${RECIPE_DIR}/overwriteProp.cmake

# Build step
emmake make -j8

# Install step
emmake make install -j8

cp -r ../include/sparrow_ipc "$PREFIX/include/"
rm -rf "$PREFIX/include/include/sparrow_ipc"

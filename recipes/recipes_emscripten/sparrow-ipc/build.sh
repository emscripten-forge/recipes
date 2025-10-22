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
  -Dflatbuffers_DIR=$PREFIX/lib/cmake/flatbuffers

# Build step
emmake make -j8

emcc libsparrow-ipc.a \
  $EM_FORGE_SIDE_MODULE_LDFLAGS \
  -o libsparrow-ipc.so

# Install step
emmake make install -j8

# Manually install the shared library
cp libsparrow-ipc.so "$PREFIX/lib/"

cp -r ../include/sparrow_ipc "$PREFIX/include/"
rm -rf "$PREFIX/include/include/sparrow_ipc"

#!/bin/bash
set -e

export CXXFLAGS="${CXXFLAGS} -fPIC"
export CFLAGS="${CFLAGS} -fPIC"

# Create build directory
mkdir -p build
cd build

# Configure the build with CMake
emcmake cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH=$PREFIX \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DBUILD_EXAMPLES=OFF \
  -DBUILD_TESTS=OFF \
  -DBUILD_DOCS=OFF

# Build and install
emmake make install -j8

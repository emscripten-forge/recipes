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
  -DUSE_DATE_POLYFILL=ON \
  -DSPARROW_BUILD_SHARED=OFF \
  -DBUILD_EXAMPLES=OFF \
  -DBUILD_TESTS=OFF \
  -DBUILD_DOCS=OFF

# Build step
emmake make -j8


# Install step
emmake make install -j8

# Manually install the shared library


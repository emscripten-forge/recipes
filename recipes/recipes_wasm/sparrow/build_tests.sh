#!/bin/bash
set -e

export CXXFLAGS="${CXXFLAGS} -fPIC"

# Build and run simple test using CMake
echo "Building simple test with CMake..."

mkdir -p build
cd build

emcmake cmake ../tests/. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_FIND_ROOT_PATH=$PREFIX \
  -DCMAKE_PREFIX_PATH=$PREFIX

emmake make

echo "Running simple test..."
node test_simple.js


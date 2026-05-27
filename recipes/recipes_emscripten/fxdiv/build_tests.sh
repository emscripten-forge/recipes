#!/bin/bash
set -e

export CFLAGS="${CFLAGS} ${EM_FORGE_SIDE_MODULE_CFLAGS}"

echo "Building fxdiv tests with CMake..."

mkdir -p build
cd build

emcmake cmake ../tests/. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_FIND_ROOT_PATH=$PREFIX \
  -DCMAKE_PREFIX_PATH=$PREFIX

emmake make

echo "Running fxdiv tests..."
node test_fxdiv.js

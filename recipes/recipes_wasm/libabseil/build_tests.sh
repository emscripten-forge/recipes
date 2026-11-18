#!/bin/bash
set -e

# The Emscripten CMake toolchain derives CMAKE_SIZEOF_VOID_P from
# CMAKE_C_FLAGS, which stays empty for this CXX-only test project. On
# emscripten-wasm64 that makes abslConfigVersion.cmake report the installed
# package as 32-bit (unsuitable) and find_package(absl REQUIRED) fails, so
# pass the flags set by the platform activation explicitly.
CFLAGS="${CFLAGS:-}"
CXXFLAGS="${CXXFLAGS:-}"

echo "=========================================="
echo "Building libabseil tests..."
echo "=========================================="

mkdir -p build_tests
cd build_tests

emcmake cmake ../tests \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_FLAGS="${CFLAGS}" \
    -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
    -DCMAKE_FIND_ROOT_PATH=$PREFIX \
    -DCMAKE_PREFIX_PATH=$PREFIX

emmake ninja

echo "Running libabseil tests..."
node test_abseil.js

echo "=========================================="
echo "All libabseil tests passed!"
echo "=========================================="

#!/bin/bash
set -e

echo "=========================================="
echo "Building libabseil tests..."
echo "=========================================="

mkdir -p build_tests
cd build_tests

emcmake cmake ../tests \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_FIND_ROOT_PATH=$PREFIX \
    -DCMAKE_PREFIX_PATH=$PREFIX

emmake ninja

echo "Running libabseil tests..."
node test_abseil.js

echo "=========================================="
echo "All libabseil tests passed!"
echo "=========================================="

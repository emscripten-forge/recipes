#!/bin/bash
set -e

echo "=========================================="
echo "Building minja tests..."
echo "=========================================="

mkdir -p build_tests
cd build_tests

emcmake cmake ../tests \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_FIND_ROOT_PATH=$PREFIX \
    -DCMAKE_PREFIX_PATH=$PREFIX

emmake ninja

echo "Running minja tests..."
node test_minja.js

echo "=========================================="
echo "All minja tests passed!"
echo "=========================================="

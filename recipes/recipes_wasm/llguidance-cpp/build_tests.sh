#!/bin/bash
set -e

echo "=========================================="
echo "Building llguidance tests..."
echo "=========================================="

mkdir -p build_tests
cd build_tests

emcmake cmake ../tests \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH=$PREFIX \
    -DCMAKE_FIND_ROOT_PATH=$PREFIX

emmake ninja

echo "Running llguidance tests..."
node test_llguidance.js

echo "=========================================="
echo "All llguidance tests passed!"
echo "=========================================="

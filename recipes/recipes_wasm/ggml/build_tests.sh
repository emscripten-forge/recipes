#!/bin/bash
set -euo pipefail

echo "=========================================="
echo "Building ggml consumer tests..."
echo "=========================================="

emcmake cmake -S tests -B build_tests \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="${PREFIX}" \
  -DCMAKE_FIND_ROOT_PATH="${PREFIX}" \
  -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH \
  -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH

emmake ninja -C build_tests

echo "=========================================="
echo "Running ggml consumer tests under node..."
echo "=========================================="

node build_tests/test_ggml.js

echo "=========================================="
echo "All ggml consumer tests passed!"
echo "=========================================="

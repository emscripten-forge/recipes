#!/bin/bash
set -e

emcmake cmake -S tests -B build_tests \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="${PREFIX}" \
  -DCMAKE_FIND_ROOT_PATH="${PREFIX}"

emmake make -C build_tests -j"${CPU_COUNT}"

echo "Running test..."
node build_tests/test_proxsuite.js

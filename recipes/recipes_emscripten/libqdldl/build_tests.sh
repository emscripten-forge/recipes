#!/bin/bash
set -euo pipefail

emcmake cmake -S tests -B build_tests \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="${PREFIX}" \
  -DCMAKE_FIND_ROOT_PATH="${PREFIX}" \
  -Dqdldl_DIR="${PREFIX}/lib/cmake/qdldl"

emmake make -C build_tests -j"${CPU_COUNT}"

node build_tests/test_qdldl.js

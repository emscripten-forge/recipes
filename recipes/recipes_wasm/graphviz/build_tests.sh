#!/bin/bash
set -e

emcmake cmake ${CMAKE_ARGS} -S tests -B build_tests \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="${PREFIX}" \
  -DGraphviz_DIR="${PREFIX}/lib/cmake/Graphviz" \
  -DCMAKE_FIND_ROOT_PATH="${PREFIX}"

emmake make -C build_tests -j"${CPU_COUNT:-2}"

echo "Running test..."
node build_tests/test_graphviz.js

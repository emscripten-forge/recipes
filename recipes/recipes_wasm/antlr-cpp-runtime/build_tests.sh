#!/bin/bash
set -e

export CFLAGS="${CFLAGS:-}"
export CXXFLAGS="${CXXFLAGS:-}"

emcmake cmake -S tests -B build_tests \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DCMAKE_FIND_ROOT_PATH="${PREFIX}" \
    -DCMAKE_CXX_STANDARD=17

emmake make -C build_tests -j"${CPU_COUNT:-1}"

echo "Running test..."
node build_tests/test_antlr4_runtime.js

#!/bin/bash
set -e

# Emscripten.cmake detects the wasm64 ABI from CMAKE_C_FLAGS, so the
# activation flags (-m64) must be passed through explicitly for the test
# project, which only enables CXX.
emcmake cmake -S tests -B build_tests -GNinja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="${PREFIX}" \
  -DCMAKE_FIND_ROOT_PATH="${PREFIX}" \
  -DCMAKE_C_FLAGS="${CFLAGS:-}" \
  -DCMAKE_CXX_FLAGS="${CXXFLAGS:-}"

cmake --build build_tests --parallel "${CPU_COUNT}"

echo "Running test..."
node build_tests/test_onetbb.js

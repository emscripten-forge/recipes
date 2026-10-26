#!/bin/bash
set -euo pipefail

# Build the consumer project via find_package(gflags) and the exported `gflags` target.
# Only the single-threaded gflags_nothreads library is shipped for wasm.
emcmake cmake -S tests -B build_tests \
  -GNinja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="${PREFIX}" \
  -DCMAKE_FIND_ROOT_PATH="${PREFIX}"

ninja -C build_tests

node build_tests/test_gflags.js

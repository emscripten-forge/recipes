#!/bin/bash
set -e

# For test executables, use standalone flags (not side module flags)
export CFLAGS="${CFLAGS}"
export CXXFLAGS="${CXXFLAGS}"

emcmake cmake -S tests -B build_tests \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="${PREFIX}" \
  -DCMAKE_FIND_ROOT_PATH="${PREFIX}"

emmake make -C build_tests

echo "Running curl tests..."
node build_tests/test_curl.js

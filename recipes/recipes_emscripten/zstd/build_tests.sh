#!/bin/bash
set -e  # Exit on error

# Don't use SIDE_MODULE flags for tests - they need to be standalone executables
export CFLAGS="${CFLAGS}"
export CXXFLAGS="${CXXFLAGS}"
export LDFLAGS="${LDFLAGS}"

# Build the tests
emcmake cmake -S tests -B build_tests \
  "-DCMAKE_PREFIX_PATH=${PREFIX}" \
  "-Dzstd_DIR=${PREFIX}/lib/cmake/zstd" \
  -DCMAKE_BUILD_TYPE=Release

emmake make -C build_tests

# Run the test with Node.js
echo "Running zstd tests..."
node build_tests/test_zstd

#!/bin/bash
set -e  # Exit on error

# Don't use SIDE_MODULE flags for tests - they need to be standalone executables
export CFLAGS="${CFLAGS}"
export CXXFLAGS="${CXXFLAGS}"
export LDFLAGS="${LDFLAGS}"

# Build the tests
emcmake cmake -S tests -B build_tests \
  "-DCMAKE_PREFIX_PATH=${PREFIX}" \
  "-DOpenSSL_DIR=${PREFIX}/lib/cmake/OpenSSL" \
  -DCMAKE_BUILD_TYPE=Release

emmake make -C build_tests

# Run the test with Node.js
echo "Running OpenSSL tests..."
node build_tests/test_openssl

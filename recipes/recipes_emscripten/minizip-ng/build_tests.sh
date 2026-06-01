#!/bin/bash
set -e

# Set compiler flags for standalone executable (not side module)
export CFLAGS="$CFLAGS $EM_FORGE_CFLAGS_BASE -I${PREFIX}/include"
export CXXFLAGS="$CXXFLAGS $EM_FORGE_CFLAGS_BASE -I${PREFIX}/include"
export LDFLAGS="$LDFLAGS $EM_FORGE_LDFLAGS_BASE"

# Build the test directly (no find_package needed - use PREFIX paths)
emcmake cmake -S tests -B build_tests \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH=$PREFIX

emmake ninja -C build_tests

# Run the tests
echo "Running minizip-ng tests..."
node build_tests/test_minizip.js

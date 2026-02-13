#!/bin/bash
set -e

# Don't use side module flags for test executable - we want a runnable executable
# export CFLAGS="$CFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS"
# export CXXFLAGS="$CXXFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS"
# export LDFLAGS="$LDFLAGS $EM_FORGE_SIDE_MODULE_LDFLAGS"

emcmake cmake -S tests/thrift-cpp -B build_tests \
  -DCMAKE_PREFIX_PATH="$PREFIX" \
  -Dthrift_DIR="$PREFIX/lib/cmake/thrift"
  
emmake make -C build_tests -j${CPU_COUNT}

# Run the test with Node.js
node build_tests/test_thrift-cpp

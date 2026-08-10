#!/bin/bash
set -e

# For test executables, we need standalone mode, not side modules
export CFLAGS="$CFLAGS"
export CXXFLAGS="$CXXFLAGS"

emcmake cmake -S tests -B build_tests \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH=$PREFIX \
  -Dleveldb_DIR=$PREFIX/lib/cmake/leveldb

emmake make -C build_tests

node build_tests/test_leveldb.js

#!/bin/bash
set -e

# oneDPL with TBB backend requires pthreads
export CFLAGS="${CFLAGS} -pthread"
export CXXFLAGS="${CXXFLAGS} -pthread"

emcmake cmake -S tests -B build_tests \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="${PREFIX}" \
  -DCMAKE_FIND_ROOT_PATH="${PREFIX}" \
  -DCMAKE_CXX_FLAGS="-pthread" \
  -DCMAKE_EXE_LINKER_FLAGS="-pthread"

emmake make -C build_tests -j"${CPU_COUNT}"

echo "Running oneDPL test..."
node build_tests/test_onedpl.js

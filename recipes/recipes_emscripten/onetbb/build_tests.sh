#!/bin/bash
set -e

# -pthread must match libtbb.a build; without it the linker rejects
# --shared-memory and the test binary won't link.
# -sPROXY_TO_PTHREAD is recommended by oneTBB WASM docs:
# splits the initial thread into a browser thread + main Web Worker,
# preventing deadlocks from nested Web Worker scheduling.
export CFLAGS="${CFLAGS} -pthread"
export CXXFLAGS="${CXXFLAGS} -pthread"

emcmake cmake -S tests -B build_tests \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="${PREFIX}" \
  -DCMAKE_FIND_ROOT_PATH="${PREFIX}" \
  -DCMAKE_C_FLAGS="-pthread" \
  -DCMAKE_CXX_FLAGS="-pthread" \
  -DCMAKE_EXE_LINKER_FLAGS="-pthread -sPROXY_TO_PTHREAD"

emmake make -C build_tests -j"${CPU_COUNT}"

echo "Running TBB threading test..."
node build_tests/test_onetbb.js

echo "Running TBB malloc test..."
node build_tests/test_onetbb_malloc.js

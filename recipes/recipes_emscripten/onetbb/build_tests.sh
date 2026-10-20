#!/bin/bash
set -e

# -pthread must match libtbb.a build; without it the linker rejects
# --shared-memory and the test binary won't link.
export CFLAGS="${CFLAGS} -pthread"
export CXXFLAGS="${CXXFLAGS} -pthread"

emcmake cmake -S tests -B build_tests \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="${PREFIX}" \
  -DCMAKE_FIND_ROOT_PATH="${PREFIX}" \
  -DCMAKE_CXX_FLAGS="-pthread" \
  -DCMAKE_EXE_LINKER_FLAGS="-pthread"

emmake make -C build_tests -j"${CPU_COUNT}"

echo "Running test..."
node build_tests/test_onetbb.js

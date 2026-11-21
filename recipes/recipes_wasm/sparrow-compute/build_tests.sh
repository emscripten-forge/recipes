#!/bin/bash
set -e

export CXXFLAGS="${CXXFLAGS} -fPIC"

mkdir -p build
cd build

emcmake cmake ../tests/. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_FIND_ROOT_PATH=$PREFIX \
  -DCMAKE_PREFIX_PATH=$PREFIX

emmake make -j${CPU_COUNT}

# node loads the shared libsparrow.so from next to the test binary
if [ -f "${PREFIX}/lib/libsparrow.so" ]; then
  cp "${PREFIX}/lib/libsparrow.so" .
fi

echo "Running simple test..."
node test_simple.js

#!/bin/bash
set -e

export CFLAGS="$CFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS"
export CXXFLAGS="$CXXFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS"
export LDFLAGS="$LDFLAGS -L${PREFIX}/lib"

emcmake cmake -S tests -B build_tests \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="${PREFIX}" \
  -DGraphviz_DIR="${PREFIX}/lib/cmake/Graphviz" \
  -DCMAKE_FIND_ROOT_PATH="${PREFIX}"

emmake make -C build_tests -j"${CPU_COUNT}"

echo "Running test..."
node build_tests/test_graphviz.js

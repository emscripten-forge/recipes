#!/bin/bash
set -euo pipefail

# Build a standalone executable for the smoke test rather than a side module.
export CXXFLAGS="${CXXFLAGS:-} ${EM_FORGE_CFLAGS_BASE:-} -I${PREFIX}/include"
export LDFLAGS="${LDFLAGS:-} ${EM_FORGE_LDFLAGS_BASE:-}"

emcmake cmake -S tests -B build_tests \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -Dnanoarrow_DIR="${PREFIX}/lib/cmake/nanoarrow" \
    -DZLIB_ROOT="${PREFIX}" \
    -DZLIB_LIBRARY="${PREFIX}/lib/libz.a" \
    -DZLIB_INCLUDE_DIR="${PREFIX}/include" \
    -Diceberg_DIR="${PREFIX}/lib/cmake/iceberg"

emmake ninja -C build_tests
node build_tests/test_iceberg.js
#!/bin/bash
set -euo pipefail

export CFLAGS="${CFLAGS:-} ${EM_FORGE_CFLAGS_BASE:-} -I${PREFIX}/include"
export LDFLAGS="${LDFLAGS:-} ${EM_FORGE_LDFLAGS_BASE:-}"

emcmake cmake -S tests -B build_tests \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -Dlz4_DIR="${PREFIX}/lib/cmake/lz4" \
    -Dzstd_DIR="${PREFIX}/lib/cmake/zstd" \
    -Dnanoarrow_DIR="${PREFIX}/lib/cmake/nanoarrow"

emmake ninja -C build_tests
node build_tests/test_nanoarrow.js
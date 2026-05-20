#!/bin/bash
set -euo pipefail

# Build a standalone executable for the smoke test rather than a side module.
export CXXFLAGS="${CXXFLAGS:-} ${EM_FORGE_CFLAGS_BASE:-} -I${PREFIX}/include"
export LDFLAGS="${LDFLAGS:-} ${EM_FORGE_LDFLAGS_BASE:-}"

emcmake cmake -S tests -B build_tests \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -Dexecutorch_DIR="${PREFIX}/lib/cmake/ExecuTorch"

emmake ninja -C build_tests
node build_tests/test_executorch.js
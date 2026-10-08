#!/bin/bash
set -e

# Standalone executable flags (not side module)
export CFLAGS="$CFLAGS $EM_FORGE_CFLAGS_BASE -I${PREFIX}/include"
export LDFLAGS="$LDFLAGS $EM_FORGE_LDFLAGS_BASE"

emcmake cmake -S tests -B build_tests \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DCMAKE_FIND_ROOT_PATH="${PREFIX}"

emmake make -C build_tests -j"${CPU_COUNT}"

node build_tests/test_jasper.js

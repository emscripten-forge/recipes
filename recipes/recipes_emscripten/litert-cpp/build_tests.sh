#!/bin/bash
set -euo pipefail

emcmake cmake -S tests -B build_tests \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -Dlitert_DIR="${PREFIX}/lib/cmake/litert"

emmake ninja -C build_tests

node build_tests/test_litert.js
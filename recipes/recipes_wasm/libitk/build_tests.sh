#!/bin/bash
set -euo pipefail

emcmake cmake -S tests -B build_tests \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DITK_DIR="${PREFIX}/lib/cmake/ITK-5.4"

emmake ninja -C build_tests

node build_tests/test_itk.js

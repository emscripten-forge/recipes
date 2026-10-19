#!/bin/bash
set -euo pipefail

emcmake cmake ${CMAKE_ARGS} -S tests -B build_tests \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release

emmake ninja -C build_tests

node build_tests/test_eigen_lapack.js

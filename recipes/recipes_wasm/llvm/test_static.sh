#!/bin/bash
set -euxo pipefail

# Load installed export sets using only this package's declared dependencies.
emcmake cmake ${CMAKE_ARGS} -S tests -B test-build \
    -DCMAKE_BUILD_TYPE=Release -DPACKAGE_NAME="${PKG_NAME}"
if [[ "${PKG_NAME}" == "llvm-static" ]]; then
    emmake make -C test-build -j"${CPU_COUNT:-2}"
    node test-build/test_llvm.js
fi

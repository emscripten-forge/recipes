#!/bin/bash
set -euxo pipefail

# Configure against the installed static package alone. This catches exports
# that still reference shared libraries or files omitted from the package.
emcmake cmake ${CMAKE_ARGS} -S tests -B test-build \
    -DCMAKE_BUILD_TYPE=Release
emmake make -C test-build -j"${CPU_COUNT:-2}"
node test-build/test_llvm.js

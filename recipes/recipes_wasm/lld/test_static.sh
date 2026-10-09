#!/bin/bash
set -euxo pipefail

# Load installed exports using only the package's declared dependencies.
emcmake cmake ${CMAKE_ARGS} -S tests -B test-build \
    -DCMAKE_BUILD_TYPE=Release -DPACKAGE_NAME="${PKG_NAME}"

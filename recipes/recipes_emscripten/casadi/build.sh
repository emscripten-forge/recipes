#!/bin/bash

set -euo pipefail

mkdir -p build
cd build

# Configure with emcmake for WebAssembly compilation
emcmake cmake ${CMAKE_ARGS} .. \
    -GNinja \
    -DCMAKE_PREFIX_PATH:PATH=${PREFIX} \
    -DCMAKE_INSTALL_PREFIX:PATH=${PREFIX} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DWITH_PYTHON=ON \
    -DWITH_PYTHON3=ON \
    -DWITH_OPENMP=OFF \
    -DWITH_THREAD=OFF \
    -DWITH_DEEPBIND=OFF \
    -DWITH_EXAMPLES=OFF \
    -DWITH_EXTRA_WARNINGS=OFF \
    -DWITH_WERROR=OFF \
    -DWITH_SELFCONTAINED=ON \
    -DINSTALL_INTERNAL_HEADERS=OFF

# Build and install
emmake ninja install
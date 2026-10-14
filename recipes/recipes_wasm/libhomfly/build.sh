#!/usr/bin/env bash
set -euxo pipefail

emcmake cmake -S . -B build \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DCMAKE_C_FLAGS="-O2" \
    -DBUILD_SHARED_LIBS=OFF

cmake --build build --parallel 8
cmake --install build
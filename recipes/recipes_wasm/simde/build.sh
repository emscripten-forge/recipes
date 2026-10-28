#!/bin/bash
set -exuo pipefail

mkdir -p build
cd build

emcmake cmake -GNinja \
    ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DSIMDE_TEST_CMAKE_PACKAGING=OFF \
    ..

ninja install

# Remove .la files if any
find "${PREFIX}" -name '*.la' -delete 2>/dev/null || true

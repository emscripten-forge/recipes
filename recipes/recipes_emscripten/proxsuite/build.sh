#!/bin/bash
set -exuo pipefail

mkdir -p build
cd build

emcmake cmake -GNinja \
    ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH \
    -DBUILD_TESTING=OFF \
    -DBUILD_BENCHMARK=OFF \
    -DBUILD_DOCUMENTATION=OFF \
    -DINSTALL_DOCUMENTATION=OFF \
    -DBUILD_PYTHON_INTERFACE=OFF \
    -DBUILD_WITH_VECTORIZATION_SUPPORT=ON \
    -DBUILD_WITH_OPENMP_SUPPORT=OFF \
    ..

ninja install

# Remove .la files if any
find "${PREFIX}" -name '*.la' -delete 2>/dev/null || true

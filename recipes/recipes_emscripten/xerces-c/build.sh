#!/bin/bash
set -exuo pipefail

mkdir -p build
cd build

emcmake cmake -GNinja \
    ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_CXX_STANDARD_REQUIRED=ON \
    -DCMAKE_CXX_EXTENSIONS=OFF \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DCMAKE_FIND_ROOT_PATH="${PREFIX}" \
    -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH \
    -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH \
    -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH \
    -DICU_ROOT="${PREFIX}" \
    -DBUILD_SHARED_LIBS=OFF \
    -Dnetwork=OFF \
    -Dthreads=OFF \
    -Dsse2=OFF \
    -Dtranscoder=icu \
    -Dmessage-loader=inmemory \
    -DXERCES_BUILD_DOCS=OFF \
    -DXERCES_BUILD_SAMPLES=OFF \
    -DXERCES_BUILD_TESTS=OFF \
    ..

ninja install

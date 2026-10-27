#!/bin/bash

set -exuo pipefail

mkdir -p build
cd build

emcmake cmake -GNinja \
    ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_PREFIX_PATH=${PREFIX} \
    -DBUILD_SHARED_LIBS=OFF \
    -DABSL_PROPAGATE_CXX_STD=ON \
    ..

# Build step
ninja install

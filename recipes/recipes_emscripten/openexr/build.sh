#!/bin/bash

set -xeuo pipefail

mkdir build
cd build

cmake \
    ${CMAKE_ARGS} \
    -DBUILD_SHARED_LIBS=OFF \
    -DOPENEXR_LIB_SUFFIX="" \
    -DOPENEXR_ENABLE_THREADING=OFF \
    -DOPENEXR_ENABLE_SIMD=OFF \
    -DOPENEXR_BUILD_TOOLS=OFF \
    -DOPENEXR_BUILD_EXAMPLES=OFF \
    -DOPENEXR_BUILD_TESTS=OFF \
    ..

make -j2
make install
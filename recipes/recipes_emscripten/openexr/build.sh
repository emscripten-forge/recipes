#!/bin/bash

set -xeuo pipefail

mkdir build
cd build

cmake \
    ${CMAKE_ARGS} \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_STATIC_LIBS=ON \
    -DOPENEXR_LIB_SUFFIX="" \
    -DOPENEXR_ENABLE_THREADING=OFF \
    -DHAVE_LIBC_PTHREAD=OFF \
    ..

make -j2
make install
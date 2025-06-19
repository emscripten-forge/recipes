#!/bin/bash

set -xeuo pipefail

mkdir build
cd build

cmake \
    ${CMAKE_ARGS} \
    -DCMAKE_HAVE_LIBC_PTHREAD=OFF \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_STATIC_LIBS=ON \
    -DOPENEXR_LIB_SUFFIX="" \
    ..

make -j2
make install
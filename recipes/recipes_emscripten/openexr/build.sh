#!/bin/bash

set -xeuo pipefail

mkdir build
cd build

cmake \
    ${CMAKE_ARGS} \
    -DBUILD_SHARED_LIBS=OFF \
    -DOPENEXR_LIB_SUFFIX="" \
    -DOPENEXR_ENABLE_THREADING=OFF \
    -DCMAKE_CXX_FLAGS="-msse=none -msse2=none" \
    -DCMAKE_C_FLAGS="-msse=none -msse2=none" \
    ..

make -j2
make install
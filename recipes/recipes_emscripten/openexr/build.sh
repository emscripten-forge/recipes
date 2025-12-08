#!/bin/bash

set -xeuo pipefail

mkdir build
cd build

cmake \
    ${CMAKE_ARGS} \
    -DBUILD_SHARED_LIBS=OFF \
    -DOPENEXR_LIB_SUFFIX="" \
    -DOPENEXR_ENABLE_THREADING=OFF \
    ..

make -j2
make install
#!/bin/bash

# Build options are adapted from https://github.com/pyodide/pyodide/blob/main/packages/libheif/meta.yaml
# heif_emscripten.h is for building js APIs, but we don't want them.
sed -i 's@#include "heif_emscripten.h"@@' libheif/heif.cc
emcmake cmake \
    -DCMAKE_CXX_FLAGS="-fPIC" \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DCMAKE_PROJECT_INCLUDE=${RECIPE_DIR}/overwriteProp.cmake \
    -DWITH_EXAMPLES=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -DLIBDE265_INCLUDE_DIR=${PREFIX}/include \
    -DLIBDE265_LIBRARY=${PREFIX}/lib/libde265.a \
    ./
emmake make -j${CPU_COUNT}
emmake make install
mkdir dist
cp ${PREFIX}/lib/libheif.so dist/
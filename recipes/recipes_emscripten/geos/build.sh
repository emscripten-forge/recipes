#!/bin/bash

mkdir -p build
cd build

export LDFLAGS="$LDFLAGS -s SIDE_MODULE=1"

emcmake cmake \
    -D DISABLE_GEOS_INLINE=ON \
    -D BUILD_TESTING=OFF \
    -D BUILD_BENCHMARKS=OFF \
    -D BUILD_DOCUMENTATION=OFF \
    -D BUILD_GEOSOP=OFF \
    -D CMAKE_C_FLAGS="-fPIC" \
    -D CMAKE_CXX_FLAGS="-fPIC" \
    -D CMAKE_INSTALL_PREFIX=${PREFIX} \
    ..

emmake make -j ${CPU_COUNT:-3} ${VERBOSE_AT}
emmake make install

mkdir -p dist
cp ${PREFIX}/lib/libgeos* dist/

#!/bin/bash

mkdir build
cd build

LDFLAGS="${SIDE_MODULE_LDFLAGS}" emcmake cmake \
    -DDISABLE_GEOS_INLINE=ON \
    -DBUILD_TESTING=OFF \
    -DBUILD_BENCHMARKS=OFF \
    -DBUILD_DOCUMENTATION=OFF \
    -DBUILD_GEOSOP=OFF \
    -DCMAKE_C_FLAGS="-fPIC" \
    -DCMAKE_CXX_FLAGS="-fPIC" \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    ./

emmake make -j ${CPU_COUNT:-3} ${VERBOSE_AT}
emmake make install

mkdir -p dist
cp ${PREFIX}/lib/libgeos* dist/
#!/bin/bash

mkdir -p build && cd build

emcmake cmake ${CMAKE_ARGS} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=${PREFIX} \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DBUILD_SHARED_LIBS=ON \
      -DDISABLE_GEOS_INLINE=ON \
      -DCMAKE_PROJECT_INCLUDE=${RECIPE_DIR}/overwriteProp.cmake \
      -DBUILD_TESTING=OFF \
      -DBUILD_BENCHMARKS=OFF \
      -DBUILD_DOCUMENTATION=OFF \
      -DBUILD_GEOSOP=OFF \
      ..

emmake make -j${CPU_COUNT}

emmake make install -j${CPU_COUNT}


rm $PREFIX/lib/libgeos.so
rm $PREFIX/lib/libgeos_c.so.1
rm $PREFIX/lib/libgeos_c.so

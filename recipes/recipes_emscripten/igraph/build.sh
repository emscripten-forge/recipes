#!/bin/bash

mkdir -p build && cd build

emcmake cmake ${CMAKE_ARGS} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=${PREFIX} \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DBUILD_SHARED_LIBS=OFF \
      -DIGRAPH_USE_INTERNAL_BLAS=OFF \
      -DIGRAPH_USE_INTERNAL_LAPACK=OFF \
      -DIGRAPH_USE_INTERNAL_ARPACK=OFF \
      -DIGRAPH_USE_INTERNAL_GLPK=OFF \
      -DIGRAPH_USE_INTERNAL_GMP=OFF \
      -DBLA_VENDOR=OpenBLAS \
      -DBUILD_TESTING=OFF \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
      ..

emmake make -j${CPU_COUNT}

emmake make install
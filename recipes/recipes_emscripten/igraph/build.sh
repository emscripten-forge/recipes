#!/bin/bash

mkdir build
cd build

emcmake cmake ${CMAKE_ARGS} ..          \
    -DCMAKE_BUILD_TYPE=Release          \
    -DCMAKE_PREFIX_PATH=$PREFIX         \
    -DCMAKE_INSTALL_PREFIX=$PREFIX      \
    -DIGRAPH_USE_INTERNAL_BLAS=OFF      \
    -DIGRAPH_USE_INTERNAL_LAPACK=OFF    \
    -DIGRAPH_USE_INTERNAL_ARPACK=OFF    \
    -DIGRAPH_USE_INTERNAL_GMP=OFF       \
    -DIGRAPH_USE_INTERNAL_GLPK=OFF      \
    -DIGRAPH_ENABLE_TLS=OFF             \
    -DBUILD_SHARED_LIBS=OFF             \
    -DBUILD_TESTING=OFF                 \
    -DBLAS_LIBRARIES=$PREFIX/lib/libblas.a \
    -DLAPACK_LIBRARIES=$PREFIX/lib/liblapack.a \
    -DARPACK_LIBRARY=$PREFIX/lib/libarpack.a \
    -DARPACK_INCLUDE_DIR=$PREFIX/include/arpack \
    -DGMP_LIBRARY=$PREFIX/lib/libgmp.a  \
    -DGMP_INCLUDE_DIR=$PREFIX/include   \
    -DGLPK_LIBRARY=$PREFIX/lib/libglpk.a \
    -DGLPK_INCLUDE_DIR=$PREFIX/include

emmake make -j${CPU_COUNT:-3}
emmake make install

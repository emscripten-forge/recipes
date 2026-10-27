#!/bin/bash
set -euxo pipefail

# Use igraph's vendored (f2c-translated) BLAS/LAPACK/ARPACK so that no
# Fortran compiler or external arpack package is needed.
# TLS and OpenMP are disabled to keep pthread symbols out of the library;
# NANOFLANN_NO_THREADS stops the vendored nanoflann from using std::async.
export CXXFLAGS="${CXXFLAGS:-} -DNANOFLANN_NO_THREADS"

emcmake cmake ${CMAKE_ARGS} -S . -B _build \
    -DCMAKE_BUILD_TYPE=Release          \
    -DCMAKE_PREFIX_PATH=$PREFIX         \
    -DCMAKE_INSTALL_PREFIX=$PREFIX      \
    -DIGRAPH_USE_INTERNAL_BLAS=ON       \
    -DIGRAPH_USE_INTERNAL_LAPACK=ON     \
    -DIGRAPH_USE_INTERNAL_ARPACK=ON     \
    -DIGRAPH_USE_INTERNAL_PLFIT=ON      \
    -DIGRAPH_USE_INTERNAL_GMP=OFF       \
    -DIGRAPH_USE_INTERNAL_GLPK=OFF      \
    -DIGRAPH_GRAPHML_SUPPORT=ON         \
    -DIGRAPH_OPENMP_SUPPORT=OFF         \
    -DIGRAPH_ENABLE_TLS=OFF             \
    -DIGRAPH_ENABLE_LTO=OFF             \
    -DUSE_CCACHE=OFF                    \
    -DBUILD_SHARED_LIBS=OFF             \
    -DBUILD_TESTING=OFF                 \
    -DGMP_LIBRARY=$PREFIX/lib/libgmp.a  \
    -DGMP_INCLUDE_DIR=$PREFIX/include   \
    -DGLPK_LIBRARY=$PREFIX/lib/libglpk.a \
    -DGLPK_INCLUDE_DIR=$PREFIX/include

emmake make -C _build -j${CPU_COUNT:-3}
emmake make -C _build install

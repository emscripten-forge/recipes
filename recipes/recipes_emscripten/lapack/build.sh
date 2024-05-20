#!/bin/bash

set -ex

mkdir build
cd build

mkdir -p ${PREFIX}/include

export LDFLAGS="$LDFLAGS -fno-optimize-sibling-calls"
# export FFLAGS="$FFLAGS --fno-optimize-sibling-calls"

# CMAKE_INSTALL_LIBDIR="lib" suppresses CentOS default of lib64 (conda expects lib)

# See https://github.com/Shaikh-Ubaid/lapack/blob/lf_01/LF_README.md
emcmake cmake .. \
    -DCMAKE_Fortran_COMPILER=lfortran \
    -DCBLAS=no \
    -DLAPACKE=no \
    -DBUILD_TESTING=no \
    -DBUILD_DOUBLE=no \
    -DBUILD_COMPLEX=no \
    -DBUILD_COMPLEX16=no \
    -DLAPACKE_WITH_TMG=no \
    -DCMAKE_Fortran_PREPROCESS=yes \
    -DCMAKE_Fortran_FLAGS="--fixed-form-infer --implicit-interface" \
    -DCMAKE_INSTALL_LIBDIR="lib" \
    -DCMAKE_INSTALL_PREFIX=${PREFIX}

# emcmake cmake \
#   -DCMAKE_INSTALL_PREFIX=${PREFIX} \
#   -DCMAKE_INSTALL_LIBDIR="lib" \
#   -DBUILD_TESTING=ON \
#   -DBUILD_SHARED_LIBS=OFF \
#   -DLAPACKE=ON \
#   -DCBLAS=ON \
#   -DBUILD_DEPRECATED=ON \
#   -DTEST_FORTRAN_COMPILER=OFF \
#   ${CMAKE_ARGS} ..

make install -j${CPU_COUNT} VERBOSE=1

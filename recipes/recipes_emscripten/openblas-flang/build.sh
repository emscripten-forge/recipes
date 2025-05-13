#!/bin/bash

set -ex

emmake make libs netlib \
    NO_SHARED=1 \
    NO_FORTRAN=0 \
    TARGET=RISCV64_GENERIC \
    CC=$CC \
    FC=$FC \
    HOSTCC=gcc \
    USE_THREAD=0 \
    BINARY=64 \
    NO_LAPACK=0 \
    NO_LAPACKE=0 \
    USE_OPENMP=0

emmake make install PREFIX=$PREFIX NO_SHARED=1

mkdir -p $PREFIX/lib
cp libopenblas.a $PREFIX/lib

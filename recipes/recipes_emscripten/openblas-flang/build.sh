#!/bin/bash

set -ex

find . -type f -name "*.f" -exec sed -i "s/'Left'/'L'/Ig" {} \;
find . -type f -name "*.f" -exec sed -i "s/'Right'/'R'/Ig" {} \;
find . -type f -name "*.f" -exec sed -i "s/'Upper'/'U'/Ig" {} \;
find . -type f -name "*.f" -exec sed -i "s/'Lower'/'L'/Ig" {} \;
find . -type f -name "*.f" -exec sed -i "s/'Transpose'/'T'/Ig" {} \;
find . -type f -name "*.f" -exec sed -i "s/'No transpose'/'N'/Ig" {} \;
find . -type f -name "*.f" -exec sed -i "s/'Conjugate transpose'/'C'/Ig" {} \;
find . -type f -name "*.f" -exec sed -i "s/'Non-unit'/'N'/Ig" {} \;

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

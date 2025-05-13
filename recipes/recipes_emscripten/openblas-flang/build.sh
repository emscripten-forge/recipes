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
    CC=emcc \
    HOSTCC=gcc \
    TARGET=RISCV64_GENERIC \
    NO_LAPACKE=1 \
    USE_THREAD=0

emmake make install PREFIX=$PREFIX NO_SHARED=1

mkdir -p $PREFIX/lib
cp libopenblas.a $PREFIX/lib

emcc libopenblas.a -s SIDE_MODULE=1 -o libopenblas.so
cp libopenblas.so $PREFIX/lib

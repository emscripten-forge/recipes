#!/bin/bash

set -ex

emmake make libs netlib \
    CC=emcc \
    HOSTCC=gcc \
    TARGET=RISCV64_GENERIC \
    NO_LAPACKE=0 \
    USE_THREAD=0
    
emmake make install PREFIX=$PREFIX NO_SHARED=1

mkdir -p $PREFIX/lib
cp libopenblas.a $PREFIX/lib

emcc libopenblas.a -s SIDE_MODULE=1 -o libopenblas.so
cp libopenblas.so $PREFIX/lib

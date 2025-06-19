#!/bin/bash

set -ex

emmake make libs shared \
    CC=emcc \
    HOSTCC=gcc \
    TARGET=RISCV64_GENERIC \
    NOFORTRAN=1 \
    NO_LAPACKE=1 \
    USE_THREAD=0 \
    LDFLAGS="$EM_FORGE_SIDE_MODULE_LDFLAGS"

emmake make install PREFIX=$PREFIX

mkdir -p $PREFIX/lib
cp libopenblas.a $PREFIX/lib

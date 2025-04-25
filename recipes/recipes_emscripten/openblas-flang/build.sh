#!/bin/bash

set -ex

emmake make libs \
    NO_SHARED=1 \
    TARGET=RISCV64_GENERIC \
    CC=$CC \
    FC=$FC \
    HOSTCC=gcc \
    USE_THREAD=0 \
    BINARY=64 \
    LDFLAGS="${SIDE_MODULE_LDFLAGS}"

emmake make install PREFIX=$PREFIX NO_SHARED=1

mkdir -p $PREFIX/lib
cp libopenblas.a $PREFIX/lib
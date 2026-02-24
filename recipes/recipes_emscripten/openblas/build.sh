#!/bin/bash

set -ex

export CC=emcc
export FC=flang-new
export CCOMMON_OPT="$CFLAGS -Wno-implicit-function-declaration -Wno-macro-redefined -fwasm-exceptions -sSUPPORT_LONGJMP=wasm"
export LDFLAGS="$LDFLAGS $EM_FORGE_SIDE_MODULE_LDFLAGS $FCLIBS"

# Need to build on a single core otherwise libopenblas.so can contain undefined symbols.
export BUILD_CORES=-j1

# Shared library is created separately from static library by emcc below.
export NO_SHARED=1
export USE_THREAD=0

emmake make libs netlib \
    $BUILD_CORES \
    HOSTCC=gcc \
    TARGET=RISCV64_GENERIC

emmake make install PREFIX=$PREFIX

emcc libopenblas.a $EM_FORGE_SIDE_MODULE_LDFLAGS $FCLIBS -o libopenblas.so
cp libopenblas.so $PREFIX/lib

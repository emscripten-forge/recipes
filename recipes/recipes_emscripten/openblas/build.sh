#!/bin/bash

set -ex

export CC=emcc
export FC=flang-new
export CCOMMON_OPT="$CFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS -fwasm-exceptions -sSUPPORT_LONGJMP=wasm -Wno-implicit-function-declaration -Wno-macro-redefined"
export FCOMMON_OPT="$FFLAGS"
export LDFLAGS="$LDFLAGS $EM_FORGE_SIDE_MODULE_LDFLAGS $FCLIBS"

# It was previously necessary to build on a single core otherwise libopenblas.so can contain
# undefined symbols.  Not sure if this is still required, but keeping it in just in case.
export BUILD_CORES=-j1

export USE_THREAD=0

emmake make shared \
    $BUILD_CORES \
    HOSTCC=gcc \
    TARGET=RISCV64_GENERIC

emmake make install PREFIX=$PREFIX

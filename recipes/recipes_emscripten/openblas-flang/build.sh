#!/bin/bash

set -ex

LLVM_PKG_URL="https://github.com/IsabelParedes/llvm-project/releases/download/v20.1.7_emscripten-wasm32/llvm_emscripten-wasm32-20.1.7-h2e33cc4_5.tar.bz2"
LLVM_PKG="llvm.tar.bz2"
export LLVM_DIR=$PWD/llvm

wget -O "$LLVM_PKG" "$LLVM_PKG_URL"
mkdir -p $LLVM_DIR
tar -xjvf $LLVM_PKG -C $LLVM_DIR --exclude='info/*' --exclude='share/*' --exclude='libexec/*'

export EM_LLVM_ROOT=$LLVM_DIR

export FC=$LLVM_DIR/bin/flang-new
export FFLAGS="-g --target=wasm32-unknown-emscripten -fPIC"
export FCLIBS="-lFortranRuntime"

emmake make libs netlib \
    CC=emcc \
    HOSTCC=gcc \
    TARGET=RISCV64_GENERIC \
    NO_LAPACKE=0 \
    USE_THREAD=0 \
    INTERFACE64=0
    
emmake make install PREFIX=$PREFIX NO_SHARED=1

mkdir -p $PREFIX/lib
cp libopenblas.a $PREFIX/lib

emcc libopenblas.a -s SIDE_MODULE=1 -o libopenblas.so
cp libopenblas.so $PREFIX/lib

#!/bin/bash

# # Using flang as a WASM cross-compiler
# # https://github.com/serge-sans-paille/llvm-project/blob/feature/flang-wasm/README.wasm.md
# # https://github.com/conda-forge/flang-feedstock/pull/69
micromamba install -p $BUILD_PREFIX \
    conda-forge/label/emscripten::flang==19.1.7 \
    -y --no-channel-priority

export FC=flang-new
export F77=flang-new
export F90=flang-new
export F95=flang-new
export F18=flang-new
export FLANG=flang-new

export FPICFLAGS="-fPIC"

rm $PREFIX/lib/libFortranRuntime.a || true
mkdir -p $PREFIX/lib/
cp $BUILD_PREFIX/lib/libFortranRuntime_emscripten-wasm32.a $PREFIX/lib/libFortranRuntime.a

rm $BUILD_PREFIX/bin/clang || true
ln -s $BUILD_PREFIX/bin/clang-20 $BUILD_PREFIX/bin/clang # links to emsdk clang

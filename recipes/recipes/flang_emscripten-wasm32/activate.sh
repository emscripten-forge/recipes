#!/bin/bash

# Using flang as a WASM cross-compiler
# https://github.com/serge-sans-paille/llvm-project/blob/feature/flang-wasm/README.wasm.md
# https://github.com/conda-forge/flang-feedstock/pull/69
if [ ! -f "$BUILD_PREFIX/bin/flang-new" ]; then
    micromamba install -p $BUILD_PREFIX \
        conda-forge/label/emscripten::flang==$PKG_VERSION \
        -y --no-channel-priority

    rm $BUILD_PREFIX/bin/clang-20 || true
    ln -s $BUILD_PREFIX/opt/emsdk/upstream/bin/clang $BUILD_PREFIX/bin/clang-20
    rm -r $BUILD_PREFIX/lib/clang || true
    ln -s $BUILD_PREFIX/opt/emsdk/upstream/lib/clang $BUILD_PREFIX/lib/clang
fi

export FC=flang-new
export F77=flang-new
export F90=flang-new
export F95=flang-new
export F18=flang-new
export FLANG=flang-new

export FFLAGS="--target=wasm32-unknown-emscripten"
export FPICFLAGS="-fPIC"
export FCLIBS="-lFortranRuntime"

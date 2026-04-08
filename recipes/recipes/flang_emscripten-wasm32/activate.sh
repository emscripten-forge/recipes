#!/bin/bash

# Using flang as a WASM cross-compiler
# https://github.com/serge-sans-paille/llvm-project/blob/feature/flang-wasm/README.wasm.md
# https://github.com/conda-forge/flang-feedstock/pull/69
if [ ! -f "$BUILD_PREFIX/bin/flang" ]; then
    FLANG_CHANNEL="${FLANG_CHANNEL:-conda-forge/label/emscripten}"
    micromamba install -p $BUILD_PREFIX \
        "${FLANG_CHANNEL}::flang==$PKG_VERSION" \
        -y --no-channel-priority

    CLANG_MAJOR="${PKG_VERSION%%.*}"
    rm $BUILD_PREFIX/bin/clang-${CLANG_MAJOR} || true
    ln -s $BUILD_PREFIX/opt/emsdk/upstream/bin/clang $BUILD_PREFIX/bin/clang-${CLANG_MAJOR}
    rm -r $BUILD_PREFIX/lib/clang || true
    ln -s $BUILD_PREFIX/opt/emsdk/upstream/lib/clang $BUILD_PREFIX/lib/clang
fi

export FC=flang
export F77=flang
export F90=flang
export F95=flang
export F18=flang
export FLANG=flang

export FFLAGS="--target=wasm32-unknown-emscripten"
export FPICFLAGS="-fPIC"
export FCLIBS="-lflang_rt.runtime"

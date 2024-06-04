#!/bin/bash

set -ex

export

export FC=lfortran
export EMSDK_PATH=${EMSCRIPTEN_FORGE_EMSDK_DIR}
export FFLAGS="$FFLAGS \
    --target=wasm32-unknown-emscripten \
    --generate-object-code \
    --fixed-form-infer \
    --implicit-interface"

emconfigure ./configure \
    --prefix=$PREFIX    \
    --with-lapack=no    \
    --with-blas=no      \
    --with-readline=no

emmake make -j${CPU_COUNT}

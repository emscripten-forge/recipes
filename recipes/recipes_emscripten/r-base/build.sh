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
export FPICFLAGS="-fPIC"

export r_cv_header_zlib_h=yes
export r_cv_have_bzlib=yes

emconfigure ./configure \
    --prefix=$PREFIX    \
    --build=$BUILD      \
    --host=$HOST        \
    --with-lapack=no    \
    --with-blas=no      \
    --with-readline=no  \
    --with-x=no         \
    --with-internal-tzcode=yes \
    --with-recommended-packages=no

emmake make -j${CPU_COUNT}

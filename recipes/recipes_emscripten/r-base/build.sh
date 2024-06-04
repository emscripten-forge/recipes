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


# export LDFLAGS=${LDFLAGS//$PREFIX/$BUILD_PREFIX}
# export CPPFLAGS=${CPPFLAGS//$PREFIX/$BUILD_PREFIX}
# export NM=$($CC_FOR_BUILD -print-prog-name=nm)
# export PKG_CONFIG_PATH=${BUILD_PREFIX}/lib/pkgconfig
# export HOST=$BUILD_PREFIX
# export IS_MINIMAL_R_BUILD=1

# TODO: may need to compile twice, 1. regular, 2. cross-compile

emconfigure ./configure \
    --prefix=$PREFIX    \
    --host=$ARCH \
    --with-lapack=no    \
    --with-blas=no      \
    --with-readline=no  \
    --with-x=no         \
    --with-internal-tzcode=yes \
    --with-recommended-packages=no

emmake make -j${CPU_COUNT}

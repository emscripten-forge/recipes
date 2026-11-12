#!/bin/bash
set -ex

# configure runs BLAS test programs under node; emscripten's loader looks for
# the shared libopenblas side module next to the .js file
ln -sf "${PREFIX}/lib/libopenblas.so" ./libopenblas.so

export CPPFLAGS="-I${PREFIX}/include"
export LDFLAGS="${LDFLAGS:-} -L${PREFIX}/lib"

emconfigure ./configure \
    --host=${HOST} \
    --prefix=$PREFIX \
    --with-gmp=$PREFIX \
    --with-givaro=$PREFIX \
    --with-fflas-ffpack=$PREFIX \
    --with-ntl=$PREFIX \
    --with-flint=$PREFIX \
    --with-blas-libs="-L${PREFIX}/lib -lopenblas" \
    --without-archnative \
    --disable-openmp \
    --disable-shared \
    --enable-static

emmake make -j${CPU_COUNT:-4}

emmake make install

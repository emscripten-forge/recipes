#!/usr/bin/env bash
set -euxo pipefail

autoreconf -vfi

# configure runs a small CBLAS test program under node. libopenblas is a
# shared side module and emscripten's loader looks for NEEDED libraries next
# to the .js file, so make it visible in the build directory.
ln -sf "${PREFIX}/lib/libopenblas.so" ./libopenblas.so

export CPPFLAGS="-I${PREFIX}/include"
export LDFLAGS="${LDFLAGS:-} -L${PREFIX}/lib -sALLOW_MEMORY_GROWTH=1"
export CXXFLAGS="${CXXFLAGS:-} -std=c++11"

emconfigure ./configure \
    --host=${HOST} \
    --without-archnative \
    --disable-openmp \
    --with-blas-libs="-L${PREFIX}/lib -lopenblas" \
    --with-blas-cflags="-I${PREFIX}/include" \
    --disable-shared \
    --enable-static \
    --prefix="${PREFIX}" \
    GIVARO_CFLAGS="-I${PREFIX}/include" \
    GIVARO_LIBS="-L${PREFIX}/lib -lgivaro -lgmp"

emmake make -j${CPU_COUNT:-4}
emmake make install

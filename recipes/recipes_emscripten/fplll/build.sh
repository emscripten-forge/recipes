#!/usr/bin/env bash
set -euxo pipefail

autoreconf -vfi

SAFE_CFLAGS="${CFLAGS:-}"
SAFE_CXXFLAGS="${CXXFLAGS:-}"
SAFE_LDFLAGS="${LDFLAGS:-}"

LOCAL_CFLAGS="${SAFE_CFLAGS//-pthread/}"
LOCAL_CXXFLAGS="${SAFE_CXXFLAGS//-pthread/}"
LOCAL_LDFLAGS="${SAFE_LDFLAGS//-pthread/} -L${PREFIX}/lib -sSHARED_MEMORY=0"

emconfigure ./configure \
    --build=i686-pc-linux-gnu \
    --host=wasm32-unknown-emscripten \
    --enable-static \
    --disable-shared \
    --with-gmp="${PREFIX}" \
    --with-mpfr="${PREFIX}" \
    --prefix="${PREFIX}" \
    CFLAGS="${LOCAL_CFLAGS}" \
    CXXFLAGS="${LOCAL_CXXFLAGS}" \
    LDFLAGS="${LOCAL_LDFLAGS}"

find . -type f -name "Makefile" -exec sed -i 's/-pthread//g' {} +
find . -type f -name "Makefile" -exec sed -i 's/-lpthread//g' {} +

emmake make -j8 
emmake make install
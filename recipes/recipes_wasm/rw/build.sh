#!/usr/bin/env bash
set -euxo pipefail

autoreconf -vfi

# igraph-static is only needed for the `rw` executable; link it statically
# together with its private dependencies (glpk, gmp, libxml2, zlib, ...).
export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export PKG_CONFIG="pkg-config --static"

emconfigure ./configure \
    --build=i686-pc-linux-gnu \
    --host=${HOST} \
    --disable-shared \
    --enable-static \
    --prefix="${PREFIX}" \
    CPPFLAGS="${CPPFLAGS:-} -I${PREFIX}/include" \
    CFLAGS="${CFLAGS:-} -I${PREFIX}/include" \
    CXXFLAGS="${CXXFLAGS:-} -I${PREFIX}/include" \
    LDFLAGS="${LDFLAGS:-} -L${PREFIX}/lib"

emmake make -j${CPU_COUNT:-3}
emmake make install

# libtool only installs the JS launcher; ship the wasm module next to it
cp rw.wasm "${PREFIX}/bin/"

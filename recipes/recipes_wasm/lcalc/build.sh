#!/bin/bash
set -e

autoreconf -vfi

emconfigure ./configure \
    --prefix=$PREFIX \
    --host=${HOST} \
    --with-pari \
    CPPFLAGS="-I$PREFIX/include" \
    CXXFLAGS="${CXXFLAGS:-} -I$PREFIX/include" \
    LDFLAGS="${LDFLAGS:-} -L$PREFIX/lib" \
    LIBS="-lgmp" \
    --disable-shared \
    --enable-static

emmake make

emmake make install

cp src/lcalc/lcalc.wasm ${PREFIX}/bin/

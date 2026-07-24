#!/bin/bash
set -e

autoreconf -vfi

emconfigure ./configure \
    --prefix=$PREFIX \
    --with-pari \
    CPPFLAGS="-I$PREFIX/include" \
    CXXFLAGS="-I$PREFIX/include" \
    LDFLAGS="-L$PREFIX/lib" \
    LIBS="-lgmp"

emmake make

emmake make install

cp src/lcalc/.libs/lcalc.wasm $PREFIX/bin/
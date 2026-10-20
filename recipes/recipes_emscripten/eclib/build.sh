#!/bin/bash
set -e

autoreconf -vfi

emconfigure ./configure \
    --prefix=$PREFIX \
    --disable-shared \
    --enable-static \
    --with-flint=$PREFIX \
    --with-ntl=$PREFIX \
    --with-pari=$PREFIX \
    CPPFLAGS="-I$PREFIX/include" \
    LDFLAGS="-L$PREFIX/lib"


find . -type f -name "Makefile" -exec sed -i 's/^LIBS =.*/& -lmpfr -lgmp/g' {} +

emmake make
emmake make install

cp progs/*.wasm $PREFIX/bin

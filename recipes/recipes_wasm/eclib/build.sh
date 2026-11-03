#!/bin/bash
set -e

autoreconf -vfi

emconfigure ./configure \
    --prefix=$PREFIX \
    --host=${HOST} \
    --disable-shared \
    --enable-static \
    --with-flint=$PREFIX \
    --with-ntl=$PREFIX \
    --with-pari=$PREFIX \
    CPPFLAGS="-I$PREFIX/include" \
    LDFLAGS="${LDFLAGS:-} -L$PREFIX/lib"

# libpari/libflint need gmp/mpfr after them on the static link line
find . -type f -name "Makefile" -exec sed -i 's/^LIBS =.*/& -lmpfr -lgmp/g' {} +

emmake make
emmake make install

cp progs/*.wasm $PREFIX/bin

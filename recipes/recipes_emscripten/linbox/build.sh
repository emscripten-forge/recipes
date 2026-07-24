#!/bin/bash
set -e

emconfigure ./configure \
    --prefix=$PREFIX \
    --with-gmp=$PREFIX \
    --with-givaro=$PREFIX \
    --with-fflas-ffpack=$PREFIX \
    --with-ntl=$PREFIX \
    --with-flint=$PREFIX \
    --with-blas-libs="-lblas" \
    --without-archnative

emmake make

emmake make install
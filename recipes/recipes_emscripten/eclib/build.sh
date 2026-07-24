#!/bin/bash
set -e

autoreconf -vfi

emconfigure ./configure \
    --prefix=$PREFIX \
    --with-flint=$PREFIX \
    --with-ntl=$PREFIX \
    --with-pari=$PREFIX \
    LIBS="-lgmp"

emmake make

emmake make install
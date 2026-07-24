#!/bin/bash
set -e

autoreconf -vfi

emconfigure ./configure \
    --prefix=$PREFIX \
    --with-gmp=$PREFIX \
    --with-flint=$PREFIX \
    --with-ntl=$PREFIX \
    --with-pari=$PREFIX

emmake make

emmake make install
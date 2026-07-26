#!/usr/bin/env bash
set -euxo pipefail

autoreconf --install

emconfigure ./configure \
    --prefix=$PREFIX \
    --disable-shared \
    --enable-static

emmake make

emmake make install

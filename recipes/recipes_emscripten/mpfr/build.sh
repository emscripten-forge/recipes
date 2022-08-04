#!/bin/bash

# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* . || true

emconfigure ./configure \
    --prefix=$PREFIX \
    --with-gmp=$PREFIX

make -j${CPU_COUNT}
make install
#!/bin/bash

set -ex

# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/libtool/build-aux/config.* support/

emconfigure ./configure \
    --prefix=${PREFIX}

# make SHLIB_LIBS="$(pkg-config --libs ncurses)" -j${CPU_COUNT} ${VERBOSE_AT}
make -j${CPU_COUNT}

make install

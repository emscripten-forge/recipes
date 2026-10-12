#!/bin/bash

export CFLAGS="$CFLAGS -fwasm-exceptions"
export LDFLAGS="$LDFLAGS  -fwasm-exceptions"

mkdir build
cd build
emcmake cmake ${CMAKE_ARGS} \
    -DBUILD_TESTING=OFF \
    -DCMAKE_INSTALL_PREFIX=$PREFIX $SRC_DIR \
    -DHIGHS_NO_DEFAULT_THREADS=ON \
    -DCMAKE_INSTALL_LIBDIR=lib ..
emmake make install

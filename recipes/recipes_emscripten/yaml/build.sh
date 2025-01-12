#!/bin/bash

CFLAGS="-fPIC"

# Configure step
emconfigure ./configure --prefix=${PREFIX} \
            --enable-static     \
            --disable-shared

make -j${CPU_COUNT} ${VERBOSE_AT}
make install

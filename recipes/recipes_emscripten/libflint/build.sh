#!/bin/bash

set -ex

# Configure FLINT for emscripten target
./configure \
    --prefix=$PREFIX \
    --disable-shared \
    --enable-static \
    --with-gmp=$PREFIX \
    --with-mpfr=$PREFIX \
    --disable-pthread \
    --disable-thread-safe \
    --disable-reentrant \
    --disable-assembly \
    --enable-gmp-internals

# Build
make -j${CPU_COUNT}

# Install 
make install
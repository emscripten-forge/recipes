#!/bin/bash

set -ex

# Configure FLINT with minimal dependencies for emscripten
./configure \
    --prefix=$PREFIX \
    --host=$HOST \
    --disable-shared \
    --enable-static \
    --with-gmp=$PREFIX \
    --with-mpfr=$PREFIX \
    --disable-pthread \
    --disable-tls \
    --disable-doc \
    --disable-examples

# Build
make -j${CPU_COUNT}

# Install 
make install
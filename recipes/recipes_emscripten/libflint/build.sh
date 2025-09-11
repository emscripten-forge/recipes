#!/bin/bash

set -ex

# Get updated config files for cross-compilation
cp $BUILD_PREFIX/share/gnuconfig/config.* . || true

# Configure FLINT for emscripten target using emconfigure for cross-compilation
emconfigure ./configure \
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
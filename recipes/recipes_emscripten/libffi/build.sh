#!/bin/bash

#this build script is adapted from the libffi repo at `testsuite/emscripten/build.sh`
set -e

# Working directories
SOURCE_DIR=$PWD
TARGET=$SOURCE_DIR/build
mkdir -p "$TARGET"

# Common compiler flags
export CFLAGS="-O3 -fPIC"
export CFLAGS+=" -DWASM_BIGINT" # We need to detect WASM_BIGINT support at compile time, if bigint is not wanted simply remove
export CXXFLAGS="$CFLAGS"

# Build paths
export CPATH="$TARGET/include"
export PKG_CONFIG_PATH="$TARGET/lib/pkgconfig"
export EM_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"

# Specific variables for cross-compilation
export CHOST="wasm32-unknown-linux" # wasm32-unknown-emscripten

autoreconf -fiv
emconfigure ./configure --host=$CHOST --prefix="$TARGET" --enable-static --disable-shared --disable-dependency-tracking \
  --disable-builddir --disable-multi-os-directory --disable-raw-api --disable-docs 
make install
cp fficonfig.h build/include/
cp include/ffi_common.h build/include/

cp -r build/* $PREFIX/

# delete broken pkg-config files
rm -rf $PREFIX/lib/pkgconfig
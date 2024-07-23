#!/bin/bash

#this build script is adapted from the libffi repo at `testsuite/emscripten/build.sh`
set -e

SOURCE_DIR=$PWD

# Working directories
TARGET=$SOURCE_DIR/build
mkdir -p "$TARGET"

# compile options
WASM_BIGINT=true # JS BigInt to Wasm i64 integration
DEBUG=false

# Common compiler flags
export CFLAGS="-O3 -fPIC"
if [ "$WASM_BIGINT" = "true" ]; then
  # We need to detect WASM_BIGINT support at compile time
  export CFLAGS+=" -DWASM_BIGINT"
fi
if [ "$DEBUG" = "true" ]; then
  export CFLAGS+=" -DDEBUG_F"
fi
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
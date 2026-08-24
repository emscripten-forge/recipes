#!/bin/bash

#this build script is adapted from the libffi repo at `testsuite/emscripten/build.sh`
set -e

# GET THE TARGET_PLATFORM from the environment variable TARGET_PLATFORM
if [ -z "$target_platform" ]; then
    echo "target_platform is not set. Please set it to the target platform (e.g, wasm32-unknown-emscripten)."
    exit 1
fi

# Working directories
SOURCE_DIR=$PWD
TARGET=$SOURCE_DIR/build
mkdir -p "$TARGET"

# Common compiler flags
export CFLAGS="-O3 -fPIC 	-fwasm-exceptions -sSUPPORT_LONGJMP"
export CXXFLAGS="$CFLAGS"

export LDFLAGS="-O3  -fwasm-exceptions -sSUPPORT_LONGJMP"

# Build paths
export CPATH="$TARGET/include"
export PKG_CONFIG_PATH="$TARGET/lib/pkgconfig"
export EM_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"

# Specific variables for cross-compilation
if [[ "$target_platform" == "emscripten-wasm32" ]]; then
    export CHOST="wasm32-unknown-linux" # wasm32-unknown-emscripten
elif [[ "$target_platform" == "emscripten-wasm64" ]]; then
    export CHOST="wasm64-unknown-linux" # wasm64-unknown-emscripten
else
    echo "Unsupported target_platform: $target_platform"
    exit 1
fi


autoreconf -fiv
emconfigure ./configure --host=$CHOST --prefix="$TARGET" --enable-static --disable-shared --disable-dependency-tracking \
  --disable-builddir --disable-multi-os-directory --disable-raw-api --disable-docs 
make install
cp fficonfig.h build/include/
cp include/ffi_common.h build/include/

cp -r build/* $PREFIX/

# delete broken pkg-config files
rm -rf $PREFIX/lib/pkgconfig
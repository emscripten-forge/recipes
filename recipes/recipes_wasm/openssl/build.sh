#!/bin/bash
set -e  # Exit on error

export CFLAGS="$CFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS"
export CXXFLAGS="$CXXFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS"
export LDFLAGS="$LDFLAGS $EM_FORGE_SIDE_MODULE_LDFLAGS"


if [[ "$target_platform" == "emscripten-wasm32" ]]; then
    MEM_FLAGS=""
elif [[ "$target_platform" == "emscripten-wasm64" ]]; then
    MEM_FLAGS="-m64 -sMEMORY64=1"
else
    echo "Unsupported target_platform: $target_platform"
    exit 1
fi




CFLAGS="-fPIC -fvisibility=hidden $MEM_FLAGS" emconfigure ./Configure gcc \
      no-shared \
      no-dso \
      no-asm \
      no-tests \
      no-apps \
      no-module \
      no-threads \
      --with-rand-seed=getrandom \
      --openssldir=/etc/ssl \
      --libdir=lib \
      --cross-compile-prefix= \
      CC=emcc \
      AR=emar \
      RANLIB=emranlib \
      NM=llvm-nm \
      --prefix=${PREFIX}

emmake make -j 8 build_libs
emmake make -j 8 install_dev
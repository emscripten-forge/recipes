#!/bin/bash

# emconfigure ./configure \
#     --extra-cflags="-fPIC" \
#     --disable-x86asm \
#     --disable-asm \
#     --disable-inline-asm \
#     --disable-doc \
#     --disable-stripping \
#     --disable-programs \
#     --disable-pthreads \
#     --nm="$CONDA_EMSDK_DIR/upstream/bin/llvm-nm -g" \
#     --ar=emar --cc=emcc --cxx=em++ --objcc=emcc --dep-cc=emcc --ranlib=emranlib \
#     --prefix=${PREFIX}
# # emmake make -j${CPU_COUNT}
# emmake make
# emmake make install

# Adapted from https://itnext.io/build-ffmpeg-webassembly-version-ffmpeg-js-part-2-compile-with-emscripten-4c581e8c9a16
CFLAGS="-s USE_PTHREADS"
LDFLAGS="$CFLAGS -s INITIAL_MEMORY=33554432"

ARGS=(
    --target-os=none
    --arch=x86_32
    --enable-cross-compile
    --disable-x86asm
    --disable-asm
    --disable-inline-asm
    --disable-stripping
    --disable-pthreads
    --disable-programs
    --disable-doc
    --nm="$CONDA_EMSDK_DIR/upstream/bin/llvm-nm -g"
    --ar=emar
    --ranlib=emranlib
    --cc=emcc
    --cxx=em++
    --objcc=emcc
    --dep-cc=emcc
    --extra-cflags="$CFLAGS"
    --extra-cxxflags="$CFLAGS"
    --extra-ldflags="$LDFLAGS"
)

emconfigure ./configure "${ARGS[@]}"

emmake make -j${CPU_COUNT} -d
emmake make install
#!/bin/bash

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
)

emconfigure ./configure "${ARGS[@]}"

emmake make -j${CPU_COUNT} -d
emmake make install
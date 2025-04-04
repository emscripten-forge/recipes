#!/usr/bin/env bash


emconfigure ./configure \
    --extra-cflags="-fPIC" \
    --disable-asm \
    --disable-x86asm \
    --disable-inline-asm \
    --disable-doc \
    --disable-stripping \
    --disable-programs \
    --disable-pthreads \
    --disable-network \
    --disable-devices \
    --disable-avdevice \
    --disable-avfilter  \
    --disable-avformat \
    --nm="$CONDA_EMSDK_DIR/upstream/bin/llvm-nm -g" \
    --ar=emar --cc=emcc --cxx=em++ --objcc=emcc --dep-cc=emcc --ranlib=emranlib \
    --enable-cross-compile \
    --prefix=$PREFIX


emmake make -j4
emmake make install
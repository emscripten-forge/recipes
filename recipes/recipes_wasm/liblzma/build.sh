#!/bin/bash

emconfigure ./configure \
        CFLAGS="-fPIC -sUSE_PTHREADS=0" \
        CXXFLAGS="-fPIC -sUSE_PTHREADS=0" \
        LDFLAGS="-sUSE_PTHREADS=0" \
        --disable-threads \
        --disable-xz \
        --disable-xzdec \
        --disable-lzmadec \
        --disable-lzmainfo \
        --disable-lzma-links \
        --disable-scripts \
        --disable-doc \
        --enable-shared=no \
        --disable-dependency-tracking \
        --prefix=${PREFIX}

emmake make -j 2
emmake make install
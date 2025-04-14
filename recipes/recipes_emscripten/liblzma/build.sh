#!/bin/bash

emconfigure ./configure \
        CFLAGS="-fPIC" \
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

    emmake make -j ${PYODIDE_JOBS:-3}
    emmake make install
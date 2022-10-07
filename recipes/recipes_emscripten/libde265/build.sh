#!/bin/bash

# Build options are adapted from https://github.com/pyodide/pyodide/blob/main/packages/libde265/meta.yaml
emconfigure ./configure \
    CFLAGS="-fPIC" \
    CXXFLAGS="-fPIC" \
    --prefix=${PREFIX} \
    --disable-sse \
    --disable-dec265 \
    --disable-sherlock265 \
    --disable-shared \
    --bindir=$(pwd)/bin  # we don't want binaries so let's hide them installing locally
emmake make -j${CPU_COUNT}
emmake make install
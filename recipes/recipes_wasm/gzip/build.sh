#!/bin/bash
set -eo pipefail

emconfigure ./configure \
    CFLAGS="$CFLAGS -Os" \
    LDFLAGS="$LDFLAGS"

CONFIG_LDFLAGS="\
    -Os \
    --minify=0 \
    -sALLOW_MEMORY_GROWTH=1 \
    -sEXIT_RUNTIME=1 \
    -sEXPORTED_RUNTIME_METHODS=FS,ENV,PROXYFS,TTY \
    -sFORCE_FILESYSTEM=1 \
    -sMODULARIZE=1 \
    -lproxyfs.js \
    "

emmake make EXEEXT=.js -j${CPU_COUNT} \
    LDFLAGS="$LDFLAGS $CONFIG_LDFLAGS"

mkdir -p $PREFIX/bin
cp gzip.{js,wasm} $PREFIX/bin/

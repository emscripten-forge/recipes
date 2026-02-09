export CONFIG_LDFLAGS="\
    -Os \
    --minify=0 \
    -sALLOW_MEMORY_GROWTH=1 \
    -sEXIT_RUNTIME=1 \
    -sEXPORTED_RUNTIME_METHODS=FS,ENV,PROXYFS,TTY \
    -sFORCE_FILESYSTEM=1 \
    -sMODULARIZE=1 \
    -lproxyfs.js \
    "

emmake make \
    CFLAGS="$CFLAGS -Os" \
    LDFLAGS="$LDFLAGS $CONFIG_LDFLAGS"

mkdir -p $PREFIX/bin
cp tree $PREFIX/bin/tree.js
cp tree.wasm $PREFIX/bin/

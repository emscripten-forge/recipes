export CONFIG_CFLAGS="\
    -Os \
    "

export CONFIG_LDFLAGS="\
    -Os \
    --minify=0 \
    -sALLOW_MEMORY_GROWTH=1 \
    -sEXIT_RUNTIME=1 \
    -sEXPORTED_RUNTIME_METHODS=FS,ENV,getEnvStrings,TTY \
    -sFORCE_FILESYSTEM=1 \
    -sMODULARIZE=1 \
    "

emconfigure ./configure \
    --host=$HOST \
    CFLAGS="$CFLAGS $CONFIG_CFLAGS" \
    LDFLAGS="$LDFLAGS $CONFIG_LDFLAGS"

emmake make EXEEXT=.js -j${CPU_COUNT} LDFLAGS=" \
    $LDFLAGS \
    $CONFIG_LDFLAGS \
    "

mkdir -p $PREFIX/bin
cp find/find.{js,wasm} $PREFIX/bin/

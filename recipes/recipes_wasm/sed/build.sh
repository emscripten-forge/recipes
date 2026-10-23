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
    --build=$BUILD \
    --host=$HOST \
    --disable-acl \
    --disable-i18n \
    --disable-nls \
    --disable-threads \
    CFLAGS="$CFLAGS $CONFIG_CFLAGS" \
    LDFLAGS="$LDFLAGS $CONFIG_LDFLAGS"

emmake make sed/sed.js  LDFLAGS="$LDFLAGS $CONFIG_LDFLAGS" EXEEXT=.js

mkdir -p $PREFIX/bin
cp sed/sed.{js,wasm} $PREFIX/bin/

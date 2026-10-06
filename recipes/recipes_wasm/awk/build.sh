export EMCC_CFLAGS="$EMCC_CFLAGS -Os"

HOSTCC=${CC_FOR_BUILD:-gcc}

emmake make -j${CPU_COUNT} \
    HOSTCC="$HOSTCC" \
    CC="$CC" \
    CFLAGS="$CFLAGS -Os" \
    ALLOC="\
    -o awk.js \
    -sMODULARIZE=1 \
    -sEXIT_RUNTIME=1 \
    -sALLOW_MEMORY_GROWTH=1 \
    -sEXPORTED_RUNTIME_METHODS=FS,ENV,getEnvStrings,TTY \
    -sFORCE_FILESYSTEM=1 \
    "

mkdir -p $PREFIX/bin
cp awk.js $PREFIX/bin/
cp awk.wasm $PREFIX/bin/

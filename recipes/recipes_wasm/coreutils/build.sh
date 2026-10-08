export EMCC_CFLAGS="$EMCC_CFLAGS -Os"

export CONFIG_CFLAGS="\
    -Wno-format-security \
    "

export CONFIG_LDFLAGS="\
    --minify=0 \
    -sALLOW_MEMORY_GROWTH=1 \
    -sEXIT_RUNTIME=1 \
    -sEXPORTED_RUNTIME_METHODS=FS,ENV,PROXYFS,TTY \
    -sFORCE_FILESYSTEM=1 \
    -sMODULARIZE=1 \
    -lproxyfs.js \
    -sSTACK_SIZE=1MB \
    "

if [[ "${target_platform}" == "emscripten-wasm64" ]]; then
  host="wasm64-unknown-emscripten"
else
  host="wasm32-unknown-emscripten"
fi

emconfigure ./configure \
    --disable-acl \
    --disable-nls \
    --disable-threads \
    --disable-xattr \
    --enable-single-binary \
    --host="${host}" \
    CFLAGS="$CFLAGS $CONFIG_CFLAGS" \
    LDFLAGS="$LDFLAGS $CONFIG_LDFLAGS"

make EXEEXT=.js LDFLAGS="$LDFLAGS $CONFIG_LDFLAGS" -j$CPU_COUNT

ls -l src/coreutils*

# Manual install of just the files wanted.
mkdir -p $PREFIX/bin
cp src/coreutils.{js,wasm} $PREFIX/bin/

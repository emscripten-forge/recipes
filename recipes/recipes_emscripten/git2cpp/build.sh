cp $RECIPE_DIR/emscripten.meson.cross $SRC_DIR
cat $SRC_DIR/emscripten.meson.cross

# CLI11's pkgconfig file is installed here:
export PKG_CONFIG_PATH=$BUILD_PREFIX/share/pkgconfig

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

export CFLAGS="$CFLAGS $CONFIG_CFLAGS"
export LDFLAGS="$LDFLAGS $CONFIG_LDFLAGS"

meson setup build --cross-file emscripten.meson.cross

cd build
meson compile

mkdir -p $PREFIX/bin
cp git2cpp.{js,wasm} $PREFIX/bin/

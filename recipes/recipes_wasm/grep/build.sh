export CONFIG_CFLAGS="\
    -Os \
    "
export CONFIG_LDFLAGS="\
    -Os \
    --minify=0 \
    -sALLOW_MEMORY_GROWTH=1 \
    -sEXIT_RUNTIME=1 \
    -sEXPORTED_FUNCTIONS=_main,_raise \
    -sEXPORTED_RUNTIME_METHODS=FS,ENV,TTY \
    -sFORCE_FILESYSTEM=1 \
    -sMODULARIZE=1 \
    "

emconfigure ./configure \
    --build=$(./build-aux/config.guess) \
    --host=$HOST \
    --disable-nls \
    --disable-threads \
    CFLAGS="$CFLAGS $CONFIG_CFLAGS" \
    LDFLAGS="$LDFLAGS $CONFIG_LDFLAGS" \
    ac_cv_func_error=no \
    ac_cv_func_getprogname=no \
    ac_cv_func_rawmemchr=no \
    ac_cv_func__set_invalid_parameter_handler=no \
    ac_cv_header_error_h=no \
    gl_cv_func_sleep_works=yes

emmake make -C lib LDFLAGS="$LDFLAGS $CONFIG_LDFLAGS" EXEEXT=.js

# ERROR_ON_UNDEFINED_SYMBOLS=0 needed to avoid undefined symbol: splice
emmake make -C src LDFLAGS="$LDFLAGS $CONFIG_LDFLAGS -sERROR_ON_UNDEFINED_SYMBOLS=0" EXEEXT=.js

mkdir -p $PREFIX/bin
cp src/grep.{js,wasm} $PREFIX/bin/

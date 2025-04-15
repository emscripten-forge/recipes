export CONFIG_CFLAGS="\
    -Os \
    -Wno-implicit-function-declaration \
    "
export CONFIG_LDFLAGS="\
    -Os \
    --minify=0 \
    -sALLOW_MEMORY_GROWTH=1 \
    -sEXIT_RUNTIME=1 \
    -sEXPORTED_RUNTIME_METHODS=FS,ENV,getEnvStrings,TTY \
    -sFORCE_FILESYSTEM=1 \
    -sMODULARIZE=1 \
    -sERROR_ON_UNDEFINED_SYMBOLS=0 \
    "

emconfigure ./configure \
    --build=x86_64-linux-gnu \
    --host=wasm32-unknown-emscripten \
    --disable-nls \
    --disable-threads \
    CFLAGS="$CFLAGS $CONFIG_CFLAGS" \
    LDFLAGS="$LDFLAGS $CONFIG_LDFLAGS" \
    FORCE_UNSAFE_CONFIGURE=1 \
    TIME_T_32_BIT_OK=yes \
    ac_cv_have_decl_alarm=no \
    ac_cv_func_getprogname=no \
    ac_cv_func_rawmemchr=no \
    ac_cv_func__set_invalid_parameter_handler=no \
    gl_cv_func_sleep_works=yes

emmake make LDFLAGS="$LDFLAGS $CONFIG_LDFLAGS" EXEEXT=.js

mkdir -p $PREFIX/bin
cp src/grep.{js,wasm} $PREFIX/bin/

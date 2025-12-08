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
    -sERROR_ON_UNDEFINED_SYMBOLS=0 \
    "
# ERROR_ON_UNDEFINED_SYMBOLS=0 needed to avoid undefined symbol: splice

emconfigure ./configure \
    --disable-nls \
    --disable-threads \
    CFLAGS="$CFLAGS $CONFIG_CFLAGS" \
    LDFLAGS="$LDFLAGS $CONFIG_LDFLAGS" \
    ac_cv_func_error=no \
    ac_cv_func_getprogname=no \
    ac_cv_func_rawmemchr=no \
    ac_cv_func__set_invalid_parameter_handler=no \
    ac_cv_header_error_h=no \
    gl_cv_func_sleep_works=yes \
    gl_cv_bitsizeof_ptrdiff_t=32 \
    gl_cv_bitsizeof_sig_atomic_t=32 \
    gl_cv_bitsizeof_size_t=32 \
    gl_cv_bitsizeof_wchar_t=16 \
    gl_cv_bitsizeof_wint_t=32

emmake make LDFLAGS="$LDFLAGS $CONFIG_LDFLAGS" EXEEXT=.js

mkdir -p $PREFIX/bin
cp src/grep.{js,wasm} $PREFIX/bin/

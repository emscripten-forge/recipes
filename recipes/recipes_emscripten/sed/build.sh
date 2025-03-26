autoreconf -fiv

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
    --disable-acl \
    --disable-i18n \
    --disable-nls \
    --disable-threads \
    CFLAGS="$CFLAGS $CONFIG_CFLAGS" \
    LDFLAGS="$LDFLAGS $CONFIG_LDFLAGS" \
    gl_cv_bitsizeof_ptrdiff_t=32 \
    gl_cv_bitsizeof_sig_atomic_t=32 \
    gl_cv_bitsizeof_size_t=32 \
    gl_cv_bitsizeof_wchar_t=16 \
    gl_cv_bitsizeof_wint_t=32

emmake make sed/sed.js  LDFLAGS="$LDFLAGS $CONFIG_LDFLAGS" EXEEXT=.js

mkdir -p $PREFIX/bin
cp sed/sed.{js,wasm} $PREFIX/bin/

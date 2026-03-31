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

emconfigure ./configure \
    --disable-acl \
    --disable-nls \
    --disable-threads \
    --disable-xattr \
    --enable-single-binary \
    CFLAGS="$CFLAGS $CONFIG_CFLAGS" \
    LDFLAGS="$LDFLAGS $CONFIG_LDFLAGS" \
    gl_cv_bitsizeof_ptrdiff_t=32 \
    gl_cv_bitsizeof_sig_atomic_t=32 \
    gl_cv_bitsizeof_size_t=32 \
    gl_cv_bitsizeof_wchar_t=16 \
    gl_cv_bitsizeof_wint_t=32

make EXEEXT=.js LDFLAGS="$LDFLAGS $CONFIG_LDFLAGS" -j$CPU_COUNT

ls -l src/coreutils*

# Manual install of just the files wanted.
mkdir -p $PREFIX/bin
cp src/coreutils.{js,wasm} $PREFIX/bin/

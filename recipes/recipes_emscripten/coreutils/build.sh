ls
./bootstrap --skip-po

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
    --build=x86_64-linux-gnu \
    --host=wasm32-unknown-emscripten \
    --disable-acl \
    --disable-nls \
    --disable-threads \
    --disable-xattr \
    --enable-single-binary \
    CFLAGS="$CFLAGS $CONFIG_CFLAGS" \
    LDFLAGS="$LDFLAGS $CONFIG_LDFLAGS" \
    FORCE_UNSAFE_CONFIGURE=1 \
    TIME_T_32_BIT_OK=yes \
    ac_cv_have_decl_alarm=no \
    gl_cv_func_sleep_works=yes

echo "sed"
sed -i 's|$(MAKE) src/make-prime-list$(EXEEXT)|gcc src/make-prime-list.c -o src/make-prime-list$(EXEEXT) -Ilib/|' Makefile

make EXEEXT=.js CFLAGS="$CFLAGS $CONFIG_CFLAGS" LDFLAGS="$LDFLAGS $CONFIG_LDFLAGS" -k -j$CPU_COUNT || true

ls
ls src/coreutils.js

mkdir -p $PREFIX/bin
cp src/coreutils.{js,wasm} $PREFIX/bin/

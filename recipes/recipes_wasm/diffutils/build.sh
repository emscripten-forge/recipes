#!/bin/bash
set -eo pipefail

CONFIG_CFLAGS="\
    -Os \
    "

CONFIG_LDFLAGS="\
    -Os \
    --minify=0 \
    -sALLOW_MEMORY_GROWTH=1 \
    -sEXIT_RUNTIME=1 \
    -sEXPORTED_FUNCTIONS=_main,_raise \
    -sEXPORTED_RUNTIME_METHODS=FS,ENV,PROXYFS,TTY \
    -sFORCE_FILESYSTEM=1 \
    -sMODULARIZE=1 \
    -lproxyfs.js \
    "

emconfigure ./configure \
    --build=$(./build-aux/config.guess) \
    --host=$HOST \
    --disable-nls \
    --disable-threads \
    CFLAGS="$CFLAGS $CONFIG_CFLAGS" \
    LDFLAGS="$LDFLAGS $CONFIG_LDFLAGS" \
    gl_cv_func_strcasecmp_works=yes

emmake make -C lib -j${CPU_COUNT} \
    EXEEXT=.js \
    LDFLAGS="$LDFLAGS $CONFIG_LDFLAGS"

emmake make -C src -j${CPU_COUNT} \
    EXEEXT=.js \
    diff.js cmp.js \
    LDFLAGS="$LDFLAGS $CONFIG_LDFLAGS"

# sdiff and diff3 run `diff` as a child process (fork + exec), which emscripten
# does not implement, so only the self-contained programs are shipped.
mkdir -p $PREFIX/bin
cp src/diff.{js,wasm} $PREFIX/bin/
cp src/cmp.{js,wasm} $PREFIX/bin/

export NCURSES_CFLAGS=$($PREFIX/bin/ncurses6-config --cflags)
export NCURSES_LDFLAGS=$($PREFIX/bin/ncurses6-config --libs)
export TERMINFO=$($PREFIX/bin/ncurses6-config --terminfo)
export XTERM_256COLOR=$TERMINFO/x/xterm-256color

echo $NCURSES_CFLAGS
echo $NCURSES_LDFLAGS
ls -l $XTERM_256COLOR

export EMCC_CFLAGS="$EMCC_CFLAGS -Os"

export CFLAGS="$CFLAGS $NCURSES_CFLAGS"

export LDFLAGS="\
    $LDFLAGS \
    $NCURSES_LDFLAGS \
    --minify=0 \
    -sALLOW_MEMORY_GROWTH=1 \
    -sEXIT_RUNTIME=1 \
    -sEXPORTED_RUNTIME_METHODS=FS,ENV,PROXYFS,TTY \
    -sEXPORTED_FUNCTIONS=_main,_raise \
    -sFORCE_FILESYSTEM=1 \
    -sMODULARIZE=1 \
    -sLZ4 \
    -lproxyfs.js \
    "

emmake make -f Makefile.aut all

# The ac_cv_lib overrides below are to avoid configure failing to check them on wasm64.
emconfigure ./configure \
    --build=$BUILD \
    --host=$HOST \
    --with-regex=pcre2 \
    ac_cv_lib_tinfo_tgoto=yes \
    ac_cv_lib_ncurses_initscr=yes \

# Build less but not lessecho and lesskey.
emmake make less.js EXEEXT=.js -j${CPU_COUNT} LDFLAGS="
    $LDFLAGS \
    --preload-file $XTERM_256COLOR@/usr/local/share/terminfo/x/xterm-256color \
    "

mkdir -p $PREFIX/bin
cp less.{data,js,wasm} $PREFIX/bin/

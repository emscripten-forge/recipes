export NCURSES_CFLAGS=$($PREFIX/bin/ncurses6-config --cflags)
export NCURSES_LDFLAGS=$($PREFIX/bin/ncurses6-config --libs)
export TERMINFO=$($PREFIX/bin/ncurses6-config --terminfo)
export XTERM_256COLOR=$TERMINFO/x/xterm-256color
export NANORC=$PWD/nanorc

export CONFIG_CFLAGS="\
    $NCURSES_CFLAGS \
    -Os \
    "
export CONFIG_LDFLAGS="\
    $NCURSES_LDFLAGS \
    -Os \
    --minify=0 \
    -sALLOW_MEMORY_GROWTH=1 \
    -sEXIT_RUNTIME=1 \
    -sEXPORTED_RUNTIME_METHODS=FS,ENV,getEnvStrings,TTY \
    -sFORCE_FILESYSTEM=1 \
    -sMODULARIZE=1 \
    -sLZ4 \
    "

emconfigure ./configure \
    --build=x86_64-linux-gnu \
    --host=wasm32-unknown-emscripten \
    --disable-browser \
    --disable-dependency-tracking \
    --disable-nls \
    --disable-threads \
    --enable-color \
    --enable-multibuffer \
    --enable-nanorc \
    --sysconfdir=/etc \
    CFLAGS="$CFLAGS $CONFIG_CFLAGS" \
    LDFLAGS="$LDFLAGS $CONFIG_LDFLAGS" \
    NCURSES_CFLAGS="$NCURSES_CFLAGS" \
    NCURSES_LDFLAGS="$NCURSES_LDFLAGS" \
    gl_cv_bitsizeof_ptrdiff_t=32 \
    gl_cv_bitsizeof_sig_atomic_t=32 \
    gl_cv_bitsizeof_size_t=32 \
    gl_cv_bitsizeof_wchar_t=16 \
    gl_cv_bitsizeof_wint_t=32

# Basic nanorc file.
echo 'include "/usr/local/share/nano/*.nanorc"' > $NANORC

emmake make EXEEXT=.js -j$CPU_COUNT LDFLAGS=" \
    $LDFLAGS \
    $CONFIG_LDFLAGS \
    --preload-file $XTERM_256COLOR@/usr/local/share/terminfo/x/xterm-256color \
    --preload-file $PWD/syntax@/usr/local/share/nano \
    --preload-file $NANORC@/etc/nanorc \
    "

mkdir -p $PREFIX/bin
cp src/nano.{data,js,wasm} $PREFIX/bin/

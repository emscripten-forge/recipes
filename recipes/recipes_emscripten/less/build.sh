export NCURSES_CFLAGS=$($PREFIX/bin/ncurses6-config --cflags)
export NCURSES_LDFLAGS=$($PREFIX/bin/ncurses6-config --libs)
export TERMINFO=$($PREFIX/bin/ncurses6-config --terminfo)
export XTERM_256COLOR=$TERMINFO/x/xterm-256color

echo $NCURSES_CFLAGS
echo $NCURSES_LDFLAGS
ls -l $XTERM_256COLOR

export CONFIG_CFLAGS="\
    $NCURSES_CFLAGS \
    -Os \
    -Wno-incompatible-function-pointer-types \
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

# Use same return type for signals that is used in ncurses.
sed -i -e 's/#define RETSIGTYPE void/#define RETSIGTYPE int/g' defines.h.in

# Use ncurses' winch not local copy.
sed -i -e 's/RETSIGTYPE winch/RETSIGTYPE notwinch/g' signal.c

emconfigure ./configure \
    --host=wasm32-unknown-emscripten \
    CFLAGS="$CFLAGS $CONFIG_CFLAGS" \
    LDFLAGS="$LDFLAGS $CONFIG_LDFLAGS" \
    ac_cv_func__setjmp=no \
    ac_cv_func_popen=no \
    ac_cv_func_sigprocmask=no

# Build less but not lessecho and lesskey.
emmake make less.js EXEEXT=.js -j${CPU_COUNT} LDFLAGS=" \
    $LDFLAGS \
    $CONFIG_LDFLAGS \
    --preload-file $XTERM_256COLOR@/usr/local/share/terminfo/x/xterm-256color \
    "

mkdir -p $PREFIX/bin
cp less.{data,js,wasm} $PREFIX/bin/

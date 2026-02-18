export NCURSES_CFLAGS=$($PREFIX/bin/ncurses6-config --cflags)
export NCURSES_LDFLAGS=$($PREFIX/bin/ncurses6-config --libs-only-L)
export XTERM_256COLOR=$($PREFIX/bin/ncurses6-config --terminfo)/x/xterm-256color
export VIMRC=$PWD/vimrc

echo $NCURSES_CFLAGS
echo $NCURSES_LDFLAGS
ls -l $XTERM_256COLOR

export EMCC_CFLAGS="${EMCC_CFLAGS} -Os"

export CONFIG_CFLAGS="\
    $NCURSES_CFLAGS \
    "
export CONFIG_LDFLAGS="\
    $NCURSES_LDFLAGS \
    --minify=0 \
    -sALLOW_MEMORY_GROWTH=1 \
    -sEXIT_RUNTIME=1 \
    -sEXPORTED_RUNTIME_METHODS=FS,ENV,PROXYFS,TTY \
    -sFORCE_FILESYSTEM=1 \
    -sMODULARIZE=1 \
    -sLZ4 \
    -lproxyfs.js \
    "

emconfigure ./configure \
    --disable-nls \
    --disable-xattr \
    --host=wasm32-unknown-emscripten \
    --with-compiledby=emscripten-forge \
    --with-features=normal \
    --with-tlib=tinfo \
    CFLAGS="$CFLAGS $CONFIG_CFLAGS" \
    LDFLAGS="$LDFLAGS $CONFIG_LDFLAGS" \
    ac_cv_sizeof_int=4 \
    ac_cv_sizeof_long=8 \
    ac_cv_sizeof_off_t=4 \
    ac_cv_sizeof_time_t=4 \
    ac_cv_func_ftruncate=no

# Use /etc/vimrc for system vimrc file and turn some features on and off.
sed -ri "s/.*(#define SYS_VIMRC_FILE\s.*)/\1/" src/feature.h
echo "syntax on" > $VIMRC
echo "set termguicolors" >> $VIMRC
echo "set nobackup" >> $VIMRC
echo "set noswapfile" >> $VIMRC
echo "set nowritebackup" >> $VIMRC

# Installs runtime config files under $PWD/usr/local/share/vim
DESTDIR=$PWD make -C src installruntime

emmake make EXEEXT=.js -j4 LDFLAGS=" \
    $LDFLAGS \
    $CONFIG_LDFLAGS \
    --preload-file $PWD/usr/local/share/vim/vim92@/usr/local/share/vim/vim92 \
    --exclude-file $PWD/usr/local/share/vim/vim92/lang \
    --exclude-file $PWD/usr/local/share/vim/vim92/doc \
    --exclude-file $PWD/usr/local/share/vim/vim92/tutor \
    --preload-file $XTERM_256COLOR@/usr/local/share/terminfo/x/xterm-256color \
    --preload-file $VIMRC@/etc/vimrc \
    "

mkdir -p $PREFIX/bin
cp src/vim.{data,js,wasm} $PREFIX/bin/

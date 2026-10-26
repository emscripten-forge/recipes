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
    -sEXPORTED_FUNCTIONS=_main,_raise \
    -sFORCE_FILESYSTEM=1 \
    -sMODULARIZE=1 \
    -sLZ4 \
    -lproxyfs.js \
    "

# Specify both --build and --host so that configure runs in cross-compiling
# mode, as conftest programs built with -sMODULARIZE=1 exit successfully
# without running main(). The vim_cv_* values are the results of configure
# checks that cannot be run when cross-compiling (see src/INSTALLx.txt).
emconfigure ./configure \
    --build=$BUILD \
    --host=$HOST \
    --disable-nls \
    --disable-xattr \
    --with-compiledby=emscripten-forge \
    --with-features=normal \
    --with-tlib=tinfo \
    CFLAGS="$CFLAGS $CONFIG_CFLAGS" \
    LDFLAGS="$LDFLAGS $CONFIG_LDFLAGS" \
    ac_cv_func_ftruncate=no \
    vim_cv_getcwd_broken=no \
    vim_cv_memmove_handles_overlap=yes \
    vim_cv_stat_ignores_slash=yes \
    vim_cv_terminfo=yes \
    vim_cv_tgetent=zero \
    vim_cv_timer_create_works=no \
    vim_cv_toupper_broken=no \
    vim_cv_uname_output=emscripten \
    vim_cv_uname_r_output=unknown \
    vim_cv_uname_m_output=$ARCH

# Use /etc/vimrc for system vimrc file and turn some features on and off.
sed -E -i.bak "s/.*(#define SYS_VIMRC_FILE[[:space:]].*)/\1/" src/feature.h && rm src/feature.h.bak
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
    --js-library $RECIPE_DIR/sync_poll_timeout.js \
    --preload-file $PWD/usr/local/share/vim/vim92@/usr/local/share/vim/vim92 \
    --exclude-file $PWD/usr/local/share/vim/vim92/lang \
    --exclude-file $PWD/usr/local/share/vim/vim92/doc \
    --exclude-file $PWD/usr/local/share/vim/vim92/tutor \
    --preload-file $XTERM_256COLOR@/usr/local/share/terminfo/x/xterm-256color \
    --preload-file $VIMRC@/etc/vimrc \
    "

mkdir -p $PREFIX/bin
cp src/vim.{data,js,wasm} $PREFIX/bin/

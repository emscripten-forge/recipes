# Get an updated config.sub and config.guess
# Running autoreconf messes up the build so just copy these two files
cp $BUILD_PREFIX/share/libtool/build-aux/config.* .

# Required to avoid cross-compiling 'make_hash' and 'make_keys'
# which are temporary applications used in the build process
export BUILD_CC=$(which gcc)

# Build native tic executable, only used to compile the terminfo database during install.
# Without this, the build will use the tic it finds in the build env which may be for a different
# ncurses version and have a different OS-specific view of 'mixed-case' (true on linux, false on
# macos) and hence produce incompatible output.
mkdir -p build-native
pushd build-native
CC="${BUILD_CC}" AR=ar RANLIB=ranlib CFLAGS="" CPPFLAGS="" LDFLAGS="" \
  ../configure \
    --enable-mixed-case \
    --without-shared \
    --without-cxx \
    --without-cxx-binding \
    --without-ada \
    --without-manpages \
    --without-tests \
    --without-debug \
    --disable-widec
make -C include
make -C ncurses
make -C progs tic
popd

emconfigure ./configure \
    --build=$BUILD \
    --host=$HOST \
    --prefix=$PREFIX \
    --without-debug \
    --without-ada \
    --without-manpages \
    --with-pkg-config \
    --with-pkg-config-libdir=$PREFIX/lib/pkgconfig \
    --disable-overwrite \
    --enable-symlinks \
    --enable-termcap \
    --enable-pc-files \
    --with-termlib \
    --with-versioned-syms \
    --disable-widec \
    --disable-stripping \
    --enable-mixed-case \
    --with-build-cc=${BUILD_CC}

make sources

# Compile the terminfo database using the native tic built above, not the build env's tic
export tic_path="${SRC_DIR}/build-native/progs/tic"
make install

# Install .wasm files as well
cp ./progs/*.wasm ${PREFIX}/bin

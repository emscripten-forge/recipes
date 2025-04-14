# Get an updated config.sub and config.guess
# Running autoreconf messes up the build so just copy these two files
cp $BUILD_PREFIX/share/libtool/build-aux/config.* .

# Required to avoid cross-compiling 'make_hash' and 'make_keys'
# which are temporary applications used in the build process
export BUILD_CC=$(which gcc)
export BUILD_CFLAGS="-Wno-sWASM_BIGINT"
export BUILD_LDFLAGS="-Wno-sWASM_BIGINT"

emconfigure ./configure \
    --build=x86_64-linux-gnu \
    --host=wasm32-unknown-emscripten \
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
    --with-build-cc=${BUILD_CC} \
    --with-build-cflags=${BUILD_CFLAGS} \
    --with-build-ldflags=${BUILD_LDFLAGS}

make sources
make install

# Install .wasm files as well
cp ./progs/*.wasm ${PREFIX}/bin

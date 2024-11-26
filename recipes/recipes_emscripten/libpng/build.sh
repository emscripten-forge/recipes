# FIXME: libz.so has the wrong magic bytes
rm $PREFIX/lib/libz.so*

# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/libtool/build-aux/config.* .

# atomics and bulk-memory are required for cairo
export CFLAGS="-I$PREFIX/include -matomics -mbulk-memory"
export CPPFLAGS="-I$PREFIX/include"
export LDFLAGS="$LDFLAGS -L$PREFIX/lib"

mkdir -p build
cd build

emconfigure ../configure --prefix=$PREFIX \
            --with-zlib-prefix=$PREFIX \
            --disable-shared
# NOTE: to enable shared, the -shared flag needs to be replaced with SIDE_MODULE

emmake make -j${CPU_COUNT}
emmake make install

# Not packaging any shared libraries
rm $PREFIX/lib/libpng*.la

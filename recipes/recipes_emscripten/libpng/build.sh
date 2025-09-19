rm $PREFIX/lib/libz.so*

# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/libtool/build-aux/config.* .

export CFLAGS="-I$PREFIX/include -fPIC -fwasm-exceptions"
export CPPFLAGS="-I$PREFIX/include -fwasm-exceptions"
export LDFLAGS="$LDFLAGS -L$PREFIX/lib -fwasm-exceptions"

mkdir -p build
cd build

emconfigure ../configure --prefix=$PREFIX \
            --host=wasm32-unknown-emscripten \
            --with-zlib-prefix=$PREFIX \
            --disable-shared
# NOTE: to enable shared, the -shared flag needs to be replaced with SIDE_MODULE

emmake make -j${CPU_COUNT}
emmake make install

# Not packaging any shared libraries
rm $PREFIX/lib/libpng*.la

# Copy wasm files
cp pngfix.wasm $PREFIX/bin/
cp png-fix-itxt.wasm $PREFIX/bin/

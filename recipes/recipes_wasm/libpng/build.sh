# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/libtool/build-aux/config.* .

exception_flags="-fwasm-exceptions -sWASM_LEGACY_EXCEPTIONS=0 -sSUPPORT_LONGJMP=wasm"

export CFLAGS="-I$PREFIX/include -fPIC ${exception_flags}"
export CPPFLAGS="-I$PREFIX/include ${exception_flags}"
export LDFLAGS="$LDFLAGS -L$PREFIX/lib ${exception_flags}"

mkdir -p build
cd build

emconfigure ../configure --prefix=$PREFIX \
            --host=$HOST \
            --with-zlib-prefix=$PREFIX \
            --disable-shared

emmake make -j${CPU_COUNT}
emmake make install

# Not packaging any shared libraries
rm $PREFIX/lib/libpng*.la

# Copy wasm files
cp pngfix.wasm $PREFIX/bin/
cp png-fix-itxt.wasm $PREFIX/bin/

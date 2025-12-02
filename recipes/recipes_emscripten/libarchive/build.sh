set -ex

export CPPFLAGS="-I$PREFIX/include"
export LDFLAGS="$LDFLAGS -L$PREFIX/lib"
export LDLIBS="-lbz2 -lz -lzstd"

mkdir -p _build
cd _build

autoreconf -fiv ..
emconfigure ../configure \
  --prefix=${PREFIX} \
  --build="x86_64-conda-linux-gnu" \
  --host="wasm32-unknown-emscripten" \
  --disable-shared \
  --enable-static \
  --with-bz2lib \
  --with-zlib \
  --with-zstd \
  --enable-bsdtar=static \
  --enable-bsdcat=static \
  --enable-bsdcpio=static \
  --verbose

emmake make VERBOSE=1
emmake make install

cp bsd*.wasm $PREFIX/bin/
set -ex

export CPPFLAGS="-I$PREFIX/include"
export LDFLAGS="$LDFLAGS -L$PREFIX/lib"
export LDLIBS="-lbz2 -lz -lzstd"

mkdir -p _build
cd _build

autoreconf -fiv ..
# pthread.h only enables a mutex around libarchive's fallback arc4random;
# without threads (6x default) that lock is unnecessary
emconfigure ../configure \
  ac_cv_header_pthread_h=no \
  --prefix=${PREFIX} \
  --build="x86_64-conda-linux-gnu" \
  --host="${HOST}" \
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
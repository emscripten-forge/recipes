#!/bin/bash

cp $BUILD_PREFIX/share/gnuconfig/config.* .

emconfigure ./configure \
    CFLAGS="-fPIC" \
    --prefix=$PREFIX \
    --disable-dependency-tracking \
    --disable-shared \
    --without-python \
    --with-libxml="$PREFIX/lib" \
    --without-crypto

emmake make -j ${CPU_COUNT:-3}
chmod 755 xslt-config
emmake make install

# Copy wasm file also
cp ./xsltproc/xsltproc.wasm $PREFIX/bin/

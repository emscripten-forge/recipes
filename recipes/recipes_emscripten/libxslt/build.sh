#!/bin/bash

cp $BUILD_PREFIX/share/gnuconfig/config.* .

# sed -i.bak -e 's/-llzma //g' -e 's/-lz /-lz/g' $PREFIX/bin/xml2-config

emconfigure ./configure \
    CFLAGS="-fPIC " \
    --prefix=$PREFIX \
    --disable-dependency-tracking \
    --disable-shared \
    --without-python \
    --with-libxml="$PREFIX/lib" \
    --without-crypto

emmake make -j ${CPU_COUNT:-3}
chmod 755 xslt-config
emmake make install
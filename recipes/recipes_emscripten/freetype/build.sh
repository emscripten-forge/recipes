#!/bin/bash
# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/libtool/build-aux/config.* ./builds/unix

emconfigure ./configure --prefix=${PREFIX} \
            --with-zlib=yes \
            --with-png=yes \
            --without-harfbuzz \
            --with-bzip2=no \
            --enable-freetype-config

emmake make -j${CPU_COUNT} ${VERBOSE_AT}
emmake make install

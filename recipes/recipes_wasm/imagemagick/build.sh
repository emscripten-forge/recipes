#!/bin/bash
set -ex

export CPPFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$PREFIX/lib"

emconfigure ./configure \
    --host=${HOST} \
    --prefix=$PREFIX \
    --with-quantum-depth=8 \
    --disable-hdri \
    --disable-docs \
    --disable-static \
    --disable-openmp \
    --with-bzlib=yes \
    --with-autotrace=no \
    --with-djvu=no \
    --with-dps=no \
    --with-fftw=no \
    --with-flif=no \
    --with-fpx=no \
    --with-fontconfig=no \
    --with-freetype=no \
    --with-gslib=no \
    --with-gvc=no \
    --with-heic=no \
    --with-jbig=no \
    --with-jpeg=yes \
    --with-lcms=no \
    --with-lqr=no \
    --with-ltdl=no \
    --with-lzma=no \
    --with-magick-plus-plus=yes \
    --with-openexr=no \
    --with-openjp2=no \
    --with-pango=no \
    --with-perl=no \
    --with-png=yes \
    --with-raqm=no \
    --with-raw=no \
    --with-rsvg=yes \
    --with-tiff=yes \
    --with-webp=no \
    --with-wmf=no \
    --with-x=no \
    --with-xml=yes \
    --with-zlib=yes \
    --with-glib=no \
    --without-threads

emmake make install
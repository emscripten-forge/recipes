#!/bin/bash
# Get an updated config.sub and config.guess
# cp $BUILD_PREFIX/share/libtool/build-aux/config.* .

./configure \
    --prefix=$PREFIX \
    --with-tiff=$PREFIX \
    --with-jpeg=$PREFIX \
    --host=""

make -j${CPU_COUNT}
make install

#!/bin/bash
# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/libtool/build-aux/config.* .

emconfigure ./configure --prefix="${PREFIX}"  \
            --host="${HOST}"      \
            --enable-utf          \
            --enable-unicode-properties \
            --disable-shared
emmake make -j${CPU_COUNT} ${VERBOSE_AT}
emmake make install

# Delete man pages.
rm -rf "${PREFIX}/share"

# We can remove this when we start using the new conda-build.
find $PREFIX -name '*.la' -delete

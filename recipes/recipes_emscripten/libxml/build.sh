#!/bin/bash

# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/libtool/build-aux/config.* .

./autogen.sh

# Define TRUE/FALSE via preprocessor flags for now (until upstream fixes it).
# (Some (non-header) source files use them but not define them or include <stdbool.h> .)
export CPPFLAGS="${CPPFLAGS} -DFALSE=0 -DTRUE=1"

emconfigure ./configure --prefix="${PREFIX}" \
            CFLAGS="-fPIC" \
            --disable-dependency-tracking \
            --disable-shared \
            --without-python \
            --with-iconv="${PREFIX}" \
            --with-zlib="${PREFIX}" \
            --with-icu \
            --with-lzma="${PREFIX}" \

emmake make -j${CPU_COUNT:-3}
emmake make install
#!/bin/bash

# emconfigure ./configure \
#     CFLAGS="-fPIC" \
#     --disable-dependency-tracking \
#     --disable-shared \
#     --without-python \
#     --with-iconv="$PYODIDE_ROOT/packages/libiconv/build/libiconv-1.16/lib/.libs" \
#     --with-zlib="$PYODIDE_ROOT/packages/zlib/build/zlib-1.2.11/"
# emmake make -j ${CPU_COUNT:-3}


emconfigure ./configure \
    CFLAGS="-fPIC" \
    --prefix="$PREFIX" \
    --disable-dependency-tracking \
    --disable-shared \
    --without-python \
    --with-iconv="$PREFIX/lib" \
    --with-zlib="$PREFIX/lib"
emmake make -j ${CPU_COUNT:-3}
emmake make install
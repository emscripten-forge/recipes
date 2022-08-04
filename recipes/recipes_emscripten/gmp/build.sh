emconfigure ./configure \
    CFLAGS="$CFLAGS -fPIC" \
    --prefix=${PREFIX}  \
    --host=none         \
    --enable-cxx
    # --enable-fat

emmake make -j${CPU_COUNT}
emmake make install

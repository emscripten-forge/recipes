emconfigure ./configure \
    CFLAGS="$CFLAGS -fPIC -DFAST -DALLTRUE" \
    --prefix=${PREFIX} \
    --disable-shared

emmake make -j${CPU_COUNT}
emmake make install

emconfigure ./configure \
    CFLAGS="$CFLAGS -fPIC" \
    --with-gmp="${PREFIX}" \
    --with-mpfr="${PREFIX}" \
    --prefix=${PREFIX} \
    --disable-shared

emmake make -j${CPU_COUNT}
emmake make install
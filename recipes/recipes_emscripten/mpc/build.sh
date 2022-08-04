emconfigure ./configure \
    CFLAGS="-fPIC" \
    --with-gmp="${PREFIX}" \
    --with-mpfr="${PREFIX}" \
    --prefix=${PREFIX}


emmake make -j${CPU_COUNT}
emmake make install
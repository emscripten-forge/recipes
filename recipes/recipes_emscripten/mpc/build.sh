emconfigure ./configure \
    --with-gmp="${PREFIX}" \
    --prefix=${PREFIX}

    # --with-mpfr="${PREFIX}" \

emmake make -j${CPU_COUNT}
emmake make install
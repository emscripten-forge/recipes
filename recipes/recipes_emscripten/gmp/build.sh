emconfigure ./configure \
    --prefix=${PREFIX} \
     --enable-cxx \
     --enable-fat

emmake make -j${CPU_COUNT}
emmake make install

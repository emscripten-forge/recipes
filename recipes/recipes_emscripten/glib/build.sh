emconfigure ./configure \
    --enable-shared=no \
    --enable-static=yes \
    --with-threads=no \
    --with-pcre=internal \
    --disable-libmount \
    --prefix=${PREFIX}

emmake make install
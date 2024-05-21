emconfigure ./configure \
    --enable-shared=no \
    --enable-static=yes \
    --with-threads=no \
    --with-pcre=internal \
    --disable-libmount \
    --host=wasm32-unknown-linux \
    --prefix=${PREFIX} && \
emmake make install
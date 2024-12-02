export CFLAGS="$CFLAGS -fPIC"

emconfigure ./configure \
    --enable-shared=no \
    --enable-static=yes \
    --prefix=$PREFIX

emmake make install
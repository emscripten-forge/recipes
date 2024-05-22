mkdir build && cd build

emconfigure ../configure \
    --enable-shared=no \
    --enable-static=yes \
    --enable-threads=no \
    --prefix=$PREFIX

emmake make install
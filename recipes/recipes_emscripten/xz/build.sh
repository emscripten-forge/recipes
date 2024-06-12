mkdir build && cd build

emconfigure ../configure \
    --enable-shared=no \
    --enable-static=yes \
    --enable-threads=no \
    --prefix=$PREFIX

emmake make install

# Copy .wasm file also
cp src/xz/xz.wasm $PREFIX/bin/

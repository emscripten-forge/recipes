mkdir build && cd build

export CFLAGS="$CFLAGS -fPIC"
export CXXFLAGS="$CXXFLAGS -fPIC"

emconfigure ../configure \
    --enable-shared=no \
    --enable-static=yes \
    --enable-threads=no \
    --build="x86_64-conda-linux-gnu" \
    --host="wasm32-unknown-emscripten" \
    --prefix=$PREFIX

emmake make install

# Copy .wasm file also
cp src/xz/xz.wasm $PREFIX/bin/

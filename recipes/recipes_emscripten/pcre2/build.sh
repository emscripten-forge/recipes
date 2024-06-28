#!/bin/bash

./autogen.sh
emconfigure ./configure \
    --prefix=$PREFIX \
    --host=$HOST \
    --disable-shared \
    --enable-pcre2-16 \
    --enable-pcre2-32

make -j${CPU_COUNT}
make install

# Install wasm files as well
cp ./pcre2*.wasm $PREFIX/bin

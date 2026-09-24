#!/bin/bash

if [[ "${target_platform}" == "emscripten-wasm64" ]]; then
  host="wasm64-unknown-emscripten"
else
  host="wasm32-unknown-emscripten"
fi

export CFLAGS="$CFLAGS -fPIC -fwasm-exceptions -I$PREFIX/include"
export LDFLAGS="$LDFLAGS -fwasm-exceptions -L$PREFIX/lib"

./autogen.sh
emconfigure ./configure \
    --prefix=$PREFIX \
    --host="${host}" \
    --disable-shared \
    --enable-pcre2-16 \
    --enable-pcre2-32

make -j${CPU_COUNT}
make install

# Install wasm files as well
cp ./pcre2*.wasm $PREFIX/bin

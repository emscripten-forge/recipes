#!/bin/bash

exception_flags="-fwasm-exceptions -sWASM_LEGACY_EXCEPTIONS=0 -sSUPPORT_LONGJMP=wasm"

export CFLAGS="$CFLAGS -fPIC ${exception_flags} -I$PREFIX/include"
export LDFLAGS="$LDFLAGS ${exception_flags} -L$PREFIX/lib"
export AM_LDFLAGS="-static" # for executables

./autogen.sh

# Remove this from the copied file and use -shared only
sed -i 's/-sSIDE_MODULE=2 //g' m4/libtool.m4

emconfigure ./configure \
    --prefix=$PREFIX \
    --host="$HOST" \
    --enable-shared \
    --enable-pcre2-16 \
    --enable-pcre2-32 || cat config.log

# Needs to be removed again from the generated file
sed -i 's/-sSIDE_MODULE=2 //g' libtool

make -j${CPU_COUNT}
make install

# Install wasm files as well
cp ./pcre2*.wasm $PREFIX/bin

rm $PREFIX/lib/*.la
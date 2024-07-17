#!/bin/bash

export LDFLAGS="-s MODULARIZE=1  -s LINKABLE=1  -s EXPORT_ALL=1  -s WASM=1  -std=c++14  -s LZ4=1 -s SIDE_MODULE=1 -sWASM_BIGINT"


# include "include" in CFLAGS
INCLUDE_FLAGS="-I$PREFIX/include/python3.11 -I$PREFIX/include/"

echo "INCLUDE_FLAGS: $INCLUDE_FLAGS"

STDLIB_MODULE_CFLAGS="$INCLUDE_FLAGS"

LIB_OPENSSL=$PREFIX/lib/libssl.a

echo "EM_FORGE_SIDE_MODULE_LDFLAGS $EM_FORGE_SIDE_MODULE_LDFLAGS"

# OPENSSL_THREADS declares that OPENSSL is threadsafe. We are single threaded so everything is threadsafe.
emcc $STDLIB_MODULE_CFLAGS -c Modules/_ssl.c -o _ssl.o \
    -lssl -L $PREFIX/lib \
    -DOPENSSL_THREADS -fPIC \
    -s SIDE_MODULE=1 -s LINKABLE=1 -s EXPORT_ALL=1 -s WASM=1  \
    $EM_FORGE_SIDE_MODULE_LDFLAGS \
    $EM_FORGE_SIDE_MODULE_CFLAGS \
    -sWASM_BIGINT


SIDE_MODULE_LDFLAGS="$EM_FORGE_SIDE_MODULE_LDFLAGS"



PKG_BUILD_DIR=$PREFIX/lib/python3.11
mkdir -p ${PKG_BUILD_DIR}
emcc _ssl.o -lssl -L $PREFIX/lib $SIDE_MODULE_LDFLAGS -o ${PKG_BUILD_DIR}/_ssl.so -fPIC -sWASM_BIGINT \
    -s SIDE_MODULE=1 -s LINKABLE=1 -s EXPORT_ALL=1 -s WASM=1  
cp Lib/ssl.py $PREFIX/lib/python3.11/ssl.py


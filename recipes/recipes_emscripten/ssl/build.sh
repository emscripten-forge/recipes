#!/bin/bash

export LDFLAGS="-s MODULARIZE=1  -s LINKABLE=1  -s EXPORT_ALL=1 \
    -s WASM=1  -s SIDE_MODULE=1 -sWASM_BIGINT"


# include "include" in CFLAGS
INCLUDE_FLAGS="-I$PREFIX/include/python3.11 -I$PREFIX/include/ -I Include/ -I . -I Include/internal/"


#  'PY_STDMODULE_CFLAGS': '-DNDEBUG -g -fwrapv -O3 -Wall -O2 -g0 -fPIC  '
#                         '-DPY_CALL_TRAMPOLINE -fdiagnostics-color=always '
#                         '-std=c11 -Werror=implicit-function-declaration '
#                         '-fvisibility=hidden  -I./Include/internal -I. '
#                         '-I./Include -sUSE_BZIP2=1 -sUSE_ZLIB=1',

PY_STDMODULE_CFLAGS="-DNDEBUG -g -fwrapv -O3 -Wall -O2 -g0 -fPIC  \
    -DPY_CALL_TRAMPOLINE -fdiagnostics-color=always \
    -std=c11 -Werror=implicit-function-declaration \
    -fvisibility=hidden  -I./Include/internal -I."







echo "INCLUDE_FLAGS: $INCLUDE_FLAGS"

STDLIB_MODULE_CFLAGS=$PY_STDMODULE_CFLAGS


echo "EM_FORGE_SIDE_MODULE_LDFLAGS $EM_FORGE_SIDE_MODULE_LDFLAGS"

# OPENSSL_THREADS declares that OPENSSL is threadsafe. We are single threaded so everything is threadsafe.
emcc $STDLIB_MODULE_CFLAGS $INCLUDE_FLAGS -c Modules/_ssl.c -o _ssl.o \
    -DOPENSSL_THREADS 

SIDE_MODULE_LDFLAGS="$EM_FORGE_SIDE_MODULE_LDFLAGS"



PKG_BUILD_DIR=$PREFIX/lib/python3.11
mkdir -p ${PKG_BUILD_DIR}
emcc _ssl.o -lssl -L $PREFIX/lib $SIDE_MODULE_LDFLAGS -o ${PKG_BUILD_DIR}/_ssl.so \
    -fPIC -s MODULARIZE=1 -s LINKABLE=1  -s EXPORT_ALL=1 \
    -s WASM=1  -s SIDE_MODULE=1 -sWASM_BIGINT 

cp Lib/ssl.py $PREFIX/lib/python3.11/ssl.py


#!/bin/bash
ls $BUILD_PREFIX/venv/bin/
echo "PYTHON"

rm -r -f branding


cp $RECIPE_DIR/config/site.cfg .

# export EMCC_DEBUG=1
#export LDFLAGS="-s MODULARIZE=1  -s LINKABLE=1  -s EXPORT_ALL=1  -s WASM=1  -std=c++14  -s LZ4=1 -s SIDE_MODULE=1 -sWASM_BIGINT"



#redefine the ar command to use emar
export AR=emar
export RANLIB=emranlib

export NPY_DISABLE_SVML=1
export LDFLAGS="$LDFLAGS" 
export CFLAGS="-fno-asm -Wno-error=unknown-attributes -I$PREFIX"
export _PYTHON_HOST_PLATFORM="unknown" 
export CC=gcc
export CXX=g++

python -m pip  install . --global-option  " --cpu-dispatch=NONE --cpu-baseline=min"

rm -rf $PREFIX/bin

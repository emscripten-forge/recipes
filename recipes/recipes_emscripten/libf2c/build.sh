#!/bin/bash

cd CLAPACK-3.2.1

cp $RECIPE_DIR/extras/make.inc $SRC_DIR/CLAPACK-3.2.1/make.inc

# The archive's contents have default permission 0750. If we use docker
# to build, then we will not own the contents in the host, which means
# we cannot navigate into the folder. Setting it to 0750 makes it
# easier to debug.

ls

chmod -R o+rx .

# export LDFLAGS="$LDFLAGS -sWASM_BIGINT -fPIC"
# export CFLAGS="$CFLAGS -sWASM_BIGINT -fPIC"

ARCH="emar" emmake make -j3 f2clib
mkdir -p $PREFIX/lib
mkdir -p $PREFIX/include
cp INCLUDE/f2c.h $PREFIX/include
cp F2CLIBS/libf2c.a $PREFIX/lib
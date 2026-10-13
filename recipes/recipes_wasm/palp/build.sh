#!/bin/bash
set -e

mkdir -p $PREFIX/bin

emmake make CC="$CC" CFLAGS="$CFLAGS" all-dims

cp *.x $PREFIX/bin/
cp *.wasm $PREFIX/bin/
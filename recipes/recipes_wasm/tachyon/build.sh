#!/bin/bash
set -e

cd unix

export CFLAGS="$CFLAGS -D_GNU_SOURCE -Wno-absolute-value -DUNIX -include sys/time.h"
export LIBS="-ltachyon -lm"

emmake make ARCH=wasm CC="$CC" CXX="$CXX" CFLAGS="$CFLAGS" LIBS="$LIBS" STRIP=true all

mkdir -p $PREFIX/bin

cp ../compile/wasm/tachyon $PREFIX/bin/
cp ../compile/wasm/tachyon.wasm $PREFIX/bin/
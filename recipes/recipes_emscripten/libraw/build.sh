#!/bin/bash

cd libraw


autoreconf --install

CPPFLAGS="${CPPFLAGS} -I${PREFIX}/include" 
LDFLAGS="${LDFLAGS} -L${PREFIX}/lib"


./configure --prefix="${PREFIX}" --enable-openmp=no



make -j${CPU_COUNT}
make install
#!/bin/bash

cd libraw


# this is all so stupid..why does it not zinf fking zlib
cp ${PREFIX}/lib/libz.a .
cp ${PREFIX}/include/zlib.h .
cp ${PREFIX}/include/zconf.h .


autoreconf --install

CPPFLAGS="${CPPFLAGS} -I${PREFIX}/include" 
LDFLAGS="${LDFLAGS} -L${PREFIX}/lib"






./configure --prefix="${PREFIX}" --enable-openmp=no


CPPFLAGS="${CPPFLAGS} -I${PREFIX}/include" 
LDFLAGS="${LDFLAGS} -L${PREFIX}/lib"

make -j${CPU_COUNT}
make install
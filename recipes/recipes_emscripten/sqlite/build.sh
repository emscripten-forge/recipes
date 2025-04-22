#!/bin/bash

# Prevent running ldconfig when cross-compiling.

echo "#!/usr/bin/env bash" > ldconfig
chmod +x ldconfig
export PATH=${PWD}:$PATH

export EMSDK_HOME=${BUILD_PREFIX}/opt/emsdk

echo "HOST" $HOST
echo "BUILD" $BUILD

emconfigure  ./configure --prefix=${PREFIX} \
    --host="" \
    --enable-all \
    CFLAGS="${CFLAGS} -I${PREFIX}/include -fPIC" \
    LDFLAGS="${LDFLAGS} -L${PREFIX}/lib" \
    CPPFLAGS="-DSQLITE_OMIT_POPEN"; \


emmake make -j${CPU_COUNT} ${VERBOSE_AT}
emmake make install

make sqlite3.c
cd ext/wasm
make

# # We can remove this when we start using the new conda-build.
# find $PREFIX -name '*.la' -delete



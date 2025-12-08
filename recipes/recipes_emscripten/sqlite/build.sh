#!/bin/bash

# Prevent running ldconfig when cross-compiling.

echo "#!/usr/bin/env bash" > ldconfig
chmod +x ldconfig
export PATH=${PWD}:$PATH


echo "HOST" $HOST
echo "BUILD" $BUILD

emconfigure  ./configure --prefix=${PREFIX} \
            --build=${BUILD} \
            --host=none \
            --enable-threadsafe \
            --enable-shared=no \
            --disable-tcl \
            CFLAGS="${CFLAGS} -DSQLITE_ENABLE_COLUMN_METADATA=1 -I${PREFIX}/include -fPIC" \
            LDFLAGS="${LDFLAGS} -L${PREFIX}/lib" \
            CPPFLAGS="-DSQLITE_OMIT_POPEN"; \


emmake make -j${CPU_COUNT} ${VERBOSE_AT}
emmake make install

# # We can remove this when we start using the new conda-build.
# find $PREFIX -name '*.la' -delete



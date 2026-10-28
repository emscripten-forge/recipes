#!/bin/bash

export CFLAGS="$CFLAGS -s SIDE_MODULE=1 -Wno-implicit-function-declaration -fwasm-exceptions"
export CXXFLAGS="$CXXFLAGS -s SIDE_MODULE=1 -fwasm-exceptions"
export LDFLAGS="$LDFLAGS -s SIDE_MODULE=1 -fwasm-exceptions"

# otherwise "cython" is not properly executable
echo "add shebang to cython file"
{ echo '#!/usr/bin/env python'; cat "$BUILD_PREFIX/bin/cython"; } > cython.tmp
mv cython.tmp "$BUILD_PREFIX/bin/cython"
chmod +x "$BUILD_PREFIX/bin/cython"

${PYTHON} -m pip install . -vvv --no-deps --no-build-isolation \
    -Csetup-args="--cross-file=$MESON_CROSS_PYTHON_FILE"

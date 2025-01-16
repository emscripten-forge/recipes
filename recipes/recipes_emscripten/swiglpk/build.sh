#!/bin/bash
export LDFLAGS="$LDFLAGS -L$PREFIX/lib"
export CPPFLAGS="-I$PREFIX/include"
export CFLAGS="-I$PREFIX/include"
export GLPK_HEADER_PATH="$PREFIX/include"
${PYTHON} -m pip install .


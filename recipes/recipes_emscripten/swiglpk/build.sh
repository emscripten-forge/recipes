#!/bin/bash
export LDFLAGS="$LDFLAGS -L$PREFIX/lib"
export CPPFLAGS="$EM_FORGE_SIDE_MODULE_CFLAGS -I$PREFIX/include"
export CFLAGS=$CPPFLAGS
export GLPK_HEADER_PATH="$PREFIX/include"
export LDFLAGS=$EM_FORGE_SIDE_MODULE_LDFLAGS

    
${PYTHON} -m pip install .


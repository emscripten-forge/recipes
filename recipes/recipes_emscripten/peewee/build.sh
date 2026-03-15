#!/bin/bash

export NO_SQLITE=1

LDFLAGS="$LDFLAGS $EM_FORGE_SIDE_MODULE_LDFLAGS"
CFLAGS="$CFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS"
LDFLAGS="$LDFLAGS -L$PREFIX/lib"

export LDFLAGS
export CFLAGS

${PYTHON} -m pip install . --no-build-isolation --no-deps
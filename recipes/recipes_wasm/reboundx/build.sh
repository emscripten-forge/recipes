#!/bin/bash
set -e

export CFLAGS="$CFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS"
export LDFLAGS="$LDFLAGS $EM_FORGE_SIDE_MODULE_LDFLAGS -L${PREFIX}/lib"

${PYTHON} -m pip install . ${PIP_ARGS} --no-deps --no-build-isolation -vv

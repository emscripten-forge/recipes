#!/bin/bash

export CFLAGS="${CFLAGS:-} -I$PREFIX/include -fPIC"
export LDFLAGS="${LDFLAGS:-} -L$PREFIX/lib -fPIC"

${PYTHON} -m pip install . ${PIP_ARGS}

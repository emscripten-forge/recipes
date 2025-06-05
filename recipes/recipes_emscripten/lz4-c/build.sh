#!/bin/bash
set -ex

export CFLAGS="${CFLAGS} -O3 -fPIC"
export LDFLAGS="${LDFLAGS} -lrt"

# Build
make -j${CPU_COUNT} PREFIX=${PREFIX} VERBOSE=1

# Install
make install PREFIX=${PREFIX}

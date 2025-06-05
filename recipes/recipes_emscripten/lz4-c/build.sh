#!/bin/bash
set -ex

export CFLAGS="${CFLAGS} -O3 -fPIC"
export LDFLAGS="${LDFLAGS} -lrt"

# Build
VERBOSE=1 make -j${CPU_COUNT} PREFIX=${PREFIX} HAVE_MULTITHREAD=0

# Install
make install PREFIX=${PREFIX}

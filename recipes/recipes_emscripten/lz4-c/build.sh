#!/bin/bash
set -ex

export CFLAGS="${CFLAGS} -O3 -fPIC"
export LDFLAGS="${LDFLAGS} -lrt"

# Build
HAVE_MULTITHREAD=0 VERBOSE=1 make -j${CPU_COUNT} PREFIX=${PREFIX}

# Install
make install PREFIX=${PREFIX}

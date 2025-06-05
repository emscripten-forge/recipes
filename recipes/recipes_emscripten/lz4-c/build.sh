#!/bin/bash
set -ex

export CFLAGS="${CFLAGS} -O3 -fPIC -DLZ4IO_MULTITHREAD=0"
export LDFLAGS="${LDFLAGS} -lrt"

# Build
VERBOSE=1 make -j${CPU_COUNT} PREFIX=${PREFIX}

# Install
make install PREFIX=${PREFIX}

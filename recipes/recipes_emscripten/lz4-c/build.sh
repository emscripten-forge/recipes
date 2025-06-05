#!/bin/bash
set -ex

export CFLAGS="${CFLAGS} -O3 -fPIC -lrt"

# Build
make -j${CPU_COUNT} PREFIX=${PREFIX}

# Install
make install PREFIX=${PREFIX}

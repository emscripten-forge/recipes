#!/bin/bash

set -euxo pipefail

export CFLAGS="${CFLAGS} -std=c99"
#export CFLAGS="${CFLAGS:-} -std=c99"

make CFLAGS="${CFLAGS}"
make CFLAGS="${CFLAGS}" check test-xxhsum-c
make CFLAGS="${CFLAGS}" install

# Build step
#emmake make install -j8


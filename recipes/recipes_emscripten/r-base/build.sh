#!/bin/bash

set -ex

export

export FC=lfortran

emconfigure ./configure \
    --prefix=$PREFIX    \
    --with-lapack=no    \
    --with-blas=no

emmake make -j${CPU_COUNT}

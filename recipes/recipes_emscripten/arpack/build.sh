#!/bin/bash

set -eux

emcmake cmake -S . -B _build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_Fortran_COMPILER=$FC \
    -DCMAKE_Fortran_FLAGS="$FFLAGS" \
    -DBUILD_SHARED_LIBS=OFF \
    -DMPI=OFF \
    -DICB=ON \
    -DEIGEN=OFF \
    -DPYTHON3=OFF \
    -DEXAMPLES=OFF \
    -DTESTS=OFF

$(which cmake) --build _build -j${CPU_COUNT:-3}
$(which cmake) --install _build

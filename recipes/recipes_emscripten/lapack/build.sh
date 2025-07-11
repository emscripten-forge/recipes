#!/bin/bash

set -eux

emcmake cmake -S . -B _build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCBLAS=ON \
    -DLAPACKE=OFF \
    -DBUILD_TESTING=OFF \
    -DCMAKE_Fortran_PREPROCESS=yes \
    -DCMAKE_Fortran_COMPILER=$FC \
    -DCMAKE_Fortran_FLAGS=$FFLAGS \
    -DCMAKE_INSTALL_LIBDIR="lib" \
    -DCMAKE_INSTALL_PREFIX=$PREFIX

$(which cmake) --build _build
$(which cmake) --install _build

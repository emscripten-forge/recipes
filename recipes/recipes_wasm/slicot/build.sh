#!/bin/bash

set -eux

emcmake cmake -S . -B _build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_PREFIX_PATH=$PREFIX \
    -DCMAKE_FIND_ROOT_PATH=$PREFIX \
    -DCMAKE_Fortran_COMPILER=$FC \
    -DCMAKE_Fortran_FLAGS="$FFLAGS $FPICFLAGS $FINTRINSIC_MODS" \
    -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
    -DBUILD_SHARED_LIBS=OFF \
    -DSLICOT_TESTING=OFF \
    -DBLA_VENDOR=OpenBLAS

$(which cmake) --build _build -j${CPU_COUNT:-3}
$(which cmake) --install _build

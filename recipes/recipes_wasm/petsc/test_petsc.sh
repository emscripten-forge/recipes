#!/bin/bash
set -eux

export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
emcc test_petsc.c -o test_petsc.js \
  -sEXIT_RUNTIME=1 \
  -sALLOW_MEMORY_GROWTH=1 \
  $(pkg-config --cflags PETSc) \
  $(pkg-config --static --libs PETSc)

node test_petsc.js -pc_type lu
node test_petsc.js -ksp_type gmres -pc_type jacobi -ksp_rtol 1e-13

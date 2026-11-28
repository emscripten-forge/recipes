#!/bin/bash
set -eux

# petsc4py lives in the PETSc sdist and builds against the installed PETSc.
export PETSC_DIR="$PREFIX"
unset PETSC_ARCH

# numpy is a wasm wheel, so it cannot be imported by the build interpreter;
# petsc4py takes the include dir from this variable instead of numpy.get_include().
export NUMPY_INCLUDE="$PREFIX/lib/python${PY_VER}/site-packages/numpy/_core/include"

cd "$SRC_DIR/src/binding/petsc4py"
"$PYTHON" -m pip install . --no-deps --no-build-isolation -vv

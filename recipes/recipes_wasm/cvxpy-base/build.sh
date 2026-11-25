#!/bin/bash

set -eux

# Emscripten flags for the C++ extensions (_cvxcore, _cvxpy_sparsecholesky):
# - `-fPIC` and `SIDE_MODULE=1`: build as wasm side modules.
# - `-fwasm-exceptions`: exception handling used by the C++ sources.
# - `DNDEBUG` disables debug assertions (see https://github.com/cvxpy/cvxpy/issues/1690).
export FLAGS="-DNDEBUG -fPIC -sWASM_BIGINT -s SIDE_MODULE=1 -fwasm-exceptions"
export CXXFLAGS="${CXXFLAGS:-} ${FLAGS}"
export CFLAGS="${CFLAGS:-} ${FLAGS}"
export LDFLAGS="${LDFLAGS:-} -s MODULARIZE=1 -s LINKABLE=1 -s EXPORT_ALL=1 -s WASM=1 -s SIDE_MODULE=1 -sWASM_BIGINT -fwasm-exceptions -L$PREFIX/lib"
${PYTHON} -m pip install . --no-deps --no-build-isolation ${PIP_ARGS} -vvv

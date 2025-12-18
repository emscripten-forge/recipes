#!/bin/bash

set -eux

# `DNDEBUG` flag is used to disable debug mode, this may lead to issues.
# See: https://github.com/cvxpy/cvxpy/issues/1690
# Emscripten flags for Python extension modules:
# - `-fPIC`: Required for building shared libraries (.so files) for WebAssembly/emscripten
# targets. Without it, wasm-ld will fail with relocation errors.
# - `SIDE_MODULE=1`: Build as side module for WebAssembly
# - `WASM_BIGINT`: Enable big integer support
# - `MODULARIZE=1, LINKABLE=1, EXPORT_ALL=1`: Export Python module initialization functions
# - `fexceptions`: Enable exception handling
export FLAGS="-DNDEBUG -fPIC -sWASM_BIGINT -s SIDE_MODULE=1 -fexceptions"
export CXXFLAGS="${CXXFLAGS:-} ${FLAGS}"
export CFLAGS="${CFLAGS:-} ${FLAGS}"
export LDFLAGS="${LDFLAGS:-} -s MODULARIZE=1 -s LINKABLE=1 -s EXPORT_ALL=1 -s WASM=1 -s SIDE_MODULE=1 -sWASM_BIGINT -fexceptions -L$PREFIX/lib"
${PYTHON} -m pip install . --no-deps -vvv


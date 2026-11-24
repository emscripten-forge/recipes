#!/bin/bash
set -euxo pipefail

export PYTHONNOUSERSITE=1

# Tell ffi/build.py._is_emscripten_build() that we're cross-compiling for WASM.
# EMSDK is usually set by emscripten-forge CI already, but be explicit.
export EMSCRIPTEN=1

# Statically link LLVM into libllvmlite.so SIDE_MODULE; disable CMake IPO
# (Emscripten does its own LTO at link time via wasm-ld).
export LLVMLITE_SHARED=0
export LLVMLITE_LTO=0

# llvmlite 0.50 officially supports LLVM 22; emscripten-forge 6x ships LLVM 23.
export LLVMLITE_SKIP_LLVM_VERSION_CHECK=1

# CMake needs to find the emscripten-forge LLVM (llvm-static) AND LLD
# (lld-static) cmake configs; lldWasm + lldCommon are used by wasmlinker.cpp.
export CMAKE_ARGS="-DLLVM_DIR=$PREFIX/lib/cmake/llvm \
                   -DLLD_DIR=$PREFIX/lib/cmake/lld"

# Build the C extension (emcmake cmake is invoked by the patched ffi/build.py)
# and install the Python package into $PREFIX.
python setup.py build --force
python setup.py install --prefix="$PREFIX"


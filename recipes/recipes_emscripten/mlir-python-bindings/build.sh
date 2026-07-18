#!/bin/bash
set -euxo pipefail

export PYTHONNOUSERSITE=1

# nanobind cmake dir (from nanobind installed in the build prefix).
NANOBIND_CMAKE_DIR=$(python -m nanobind --cmake_dir)

mkdir -p build
cd build

# MLIR standalone build against the wasm LLVM+LLD in the host prefix.
# Key flags:
#   LLVM_NATIVE_TOOL_DIR     – native mlir-tblgen / llvm-tblgen / mlir-linalg-ods-yaml-gen
#   LLVM_TABLEGEN            – explicit path (also picked up via NATIVE_TOOL_DIR)
#   MLIR_TABLEGEN_EXE        – same
#   Python3_*/Python_*       – split: executable = build-prefix (native Python),
#                              include/library = host-prefix (wasm Python headers/stub)
emcmake cmake ../mlir \
    -G "Unix Makefiles" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DMLIR_STANDALONE_BUILD=ON \
    -DLLVM_DIR="${PREFIX}/lib/cmake/llvm" \
    -DLLD_DIR="${PREFIX}/lib/cmake/lld" \
    -DMLIR_ENABLE_BINDINGS_PYTHON=ON \
    -DMLIR_ENABLE_EXECUTION_ENGINE=OFF \
    -DMLIR_INCLUDE_TESTS=OFF \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_NATIVE_TOOL_DIR="${BUILD_PREFIX}/bin" \
    -DLLVM_TABLEGEN="${BUILD_PREFIX}/bin/llvm-tblgen" \
    -DMLIR_TABLEGEN_EXE="${BUILD_PREFIX}/bin/mlir-tblgen" \
    -DPython3_EXECUTABLE="${BUILD_PREFIX}/bin/python3" \
    -DPython3_INCLUDE_DIR="${PREFIX}/include/python3.13" \
    -DPython3_LIBRARY="${PREFIX}/lib/libpython3.13.a" \
    -DPython_EXECUTABLE="${BUILD_PREFIX}/bin/python3" \
    -DPython_INCLUDE_DIR="${PREFIX}/include/python3.13" \
    -DPython_LIBRARY="${PREFIX}/lib/libpython3.13.a" \
    -Dnanobind_DIR="${NANOBIND_CMAKE_DIR}"

emmake make MLIRPythonModules -j${CPU_COUNT:-4}
emmake make install

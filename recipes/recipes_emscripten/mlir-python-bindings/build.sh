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
#   LLVM_BUILD_TOOLS=OFF     – prevents wasm tools (mlir-tblgen.js, mlir-pdll.js etc.)
#                              from being compiled during `make install` (wasted build time)
#   MLIR_BINDINGS_PYTHON_INSTALL_PREFIX – override default python_packages/mlir_core/mlir
#                              so files land in site-packages/mlir (xeus-python search path)
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
    -DLLVM_BUILD_TOOLS=OFF \
    -DMLIR_BINDINGS_PYTHON_INSTALL_PREFIX="lib/python3.13/site-packages/mlir" \
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

# MLIR Python bindings are designed as namespace packages (no __init__.py in the
# source tree for mlir/, mlir/dialects/, mlir/extras/). Emscripten's MEMFS does
# not handle namespace packages reliably, so we supply __init__.py files.
#
# mlir/__init__.py pre-loads the three shared libraries (in correct dependency
# order) before any extension module's dlopen triggers neededDynlib resolution.
# Emscripten's dynamic linker resolves SIDE_MODULE dependencies by name, not by
# searching inside package directories, so these must be loaded with full paths.
cp "${RECIPE_DIR}/mlir_init.py" "${PREFIX}/lib/python3.13/site-packages/mlir/__init__.py"
touch "${PREFIX}/lib/python3.13/site-packages/mlir/dialects/__init__.py"
touch "${PREFIX}/lib/python3.13/site-packages/mlir/extras/__init__.py"

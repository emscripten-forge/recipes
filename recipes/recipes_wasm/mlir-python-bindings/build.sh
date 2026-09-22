#!/bin/bash
set -euxo pipefail

export PYTHONNOUSERSITE=1

# nanobind is a native build tool, while $PYTHON is cross-python configured
# with the selected target's sysconfig data.
NANOBIND_CMAKE_DIR=$("${BUILD_PREFIX}/bin/python3" -m nanobind --cmake_dir)
TARGET_EXT_SUFFIX=$("${PYTHON}" -c \
    'import sysconfig; print(sysconfig.get_config_var("EXT_SUFFIX"))')
PYTHON_SITE_PACKAGES="${PREFIX}/lib/python${PY_VER}/site-packages"

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
#   Python3_*/Python_*       – cross-python executable with target sysconfig;
#                              include/library from the wasm host prefix
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
    -DMLIR_BINDINGS_PYTHON_INSTALL_PREFIX="lib/python${PY_VER}/site-packages/mlir" \
    -DLLVM_NATIVE_TOOL_DIR="${BUILD_PREFIX}/bin" \
    -DLLVM_TABLEGEN="${BUILD_PREFIX}/bin/llvm-tblgen" \
    -DMLIR_TABLEGEN_EXE="${BUILD_PREFIX}/bin/mlir-tblgen" \
    -DPython3_EXECUTABLE="${PYTHON}" \
    -DPython3_INCLUDE_DIR="${PREFIX}/include/python${PY_VER}" \
    -DPython3_LIBRARY="${PREFIX}/lib/libpython${PY_VER}.a" \
    -DPython_EXECUTABLE="${PYTHON}" \
    -DPython_INCLUDE_DIR="${PREFIX}/include/python${PY_VER}" \
    -DPython_LIBRARY="${PREFIX}/lib/libpython${PY_VER}.a" \
    -DNB_SUFFIX="${TARGET_EXT_SUFFIX}" \
    -Dnanobind_DIR="${NANOBIND_CMAKE_DIR}"

# MLIRPythonModules is an ALL target, so the install build includes it. Building
# it separately first only serializes work that Make can schedule together.
emmake make -j${CPU_COUNT:-4} install

# MLIR Python bindings are designed as namespace packages (no __init__.py in the
# source tree for mlir/, mlir/dialects/, mlir/extras/). Emscripten's MEMFS does
# not handle namespace packages reliably, so we supply __init__.py files.
touch "${PYTHON_SITE_PACKAGES}/mlir/__init__.py"
touch "${PYTHON_SITE_PACKAGES}/mlir/dialects/__init__.py"
touch "${PYTHON_SITE_PACKAGES}/mlir/extras/__init__.py"

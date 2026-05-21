#!/bin/bash

set -eux

mkdir _build
cd _build

cmake -G Ninja \
    ${CMAKE_ARGS} \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_MODULE_PATH=../cmake/Modules \
    -DCMAKE_PREFIX_PATH=$PREFIX \
    -DLLVM_DEFAULT_TARGET_TRIPLE=wasm32-unknown-emscripten \
    -DLLVM_EXTERNAL_LIT=$PREFIX/bin/lit \
    -DLLVM_LIT_ARGS=-v \
    -DLLVM_CMAKE_DIR=$PREFIX/lib/cmake/llvm \
    -DLLVM_DIR=$PREFIX/lib/cmake/llvm \
    -DLLVM_TARGETS_TO_BUILD="WebAssembly" \
    -DLLVM_ENABLE_PROJECTS="clang;flang;mlir" \
    -DCLANG_DIR=$PREFIX/lib/cmake/clang \
    -DFLANG_INCLUDE_TESTS=OFF \
    -DMLIR_DIR=$PREFIX/lib/cmake/mlir \
    ../flang

cmake --build . -j4
cmake --install .

# Copy the [de]activate scripts to $PREFIX/etc/conda/[de]activate.d.
# This will allow them to be run on environment activation.
for TASK in "activate" "deactivate"
do
    mkdir -p "${PREFIX}/etc/conda/${TASK}.d"
    envsubst '$PKG_VERSION' < "${RECIPE_DIR}/${TASK}.sh" > "${PREFIX}/etc/conda/${TASK}.d/${TASK}_${PKG_NAME}.sh"
done
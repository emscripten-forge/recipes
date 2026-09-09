#!/bin/bash

set -eux

if [ -z "${FLANG_WASM64:-}" ]; then
    echo "FLANG_WASM64 is not set, it should be ON or OFF."
    exit 1
fi

if [ "${FLANG_WASM64}" = "ON" ]; then
    WASM_TARGET="wasm64-unknown-emscripten"
else
    WASM_TARGET="wasm32-unknown-emscripten"
fi

echo "WASM_TARGET is set to ${WASM_TARGET}"

mkdir _build
cd _build

cmake -G Ninja \
    ${CMAKE_ARGS} \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    -DCMAKE_PREFIX_PATH=$PREFIX \
    -DLLVM_DEFAULT_TARGET_TRIPLE="${WASM_TARGET}" \
    -DLLVM_CMAKE_DIR=$PREFIX/lib/cmake/llvm \
    -DLLVM_DIR=$PREFIX/lib/cmake/llvm \
    -DLLVM_TARGETS_TO_BUILD="WebAssembly" \
    -DCLANG_DIR=$PREFIX/lib/cmake/clang \
    -DFLANG_INCLUDE_TESTS=OFF \
    -DFLANG_RUNTIME_F128_MATH_LIB="" \
    -DFLANG_WASM64="${FLANG_WASM64}" \
    -DMLIR_DIR=$PREFIX/lib/cmake/mlir \
    ../flang

cmake --build . -j1
cmake --install .

# Copy the [de]activate scripts to $PREFIX/etc/conda/[de]activate.d.
# This will allow them to be run on environment activation.
for TASK in "activate" "deactivate"
do
    mkdir -p "${PREFIX}/etc/conda/${TASK}.d"
    envsubst '${WASM_TARGET}' < "${RECIPE_DIR}/${TASK}.sh" > "${PREFIX}/etc/conda/${TASK}.d/${TASK}_${PKG_NAME}.sh"
done

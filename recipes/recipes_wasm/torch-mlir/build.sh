#!/bin/bash
set -euxo pipefail

NANOBIND_CMAKE_DIR=$("${BUILD_PREFIX}/bin/python3" -m nanobind --cmake_dir)
TARGET_EXT_SUFFIX=$("${PYTHON}" -c 'import sysconfig; print(sysconfig.get_config_var("EXT_SUFFIX"))')

emcmake cmake ${CMAKE_ARGS} -S . -B build -G "Unix Makefiles" \
    -U 'PYTHON_*' -U PYTHONLIBS_FOUND \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DBUILD_SHARED_LIBS=OFF \
    -DLLVM_DIR="${PREFIX}/lib/cmake/llvm" \
    -DMLIR_DIR="${PREFIX}/lib/cmake/mlir" \
    -DMLIR_TABLEGEN_EXE="${BUILD_PREFIX}/bin/mlir-tblgen" \
    -DTORCH_MLIR_INCLUDE_TESTS=OFF \
    -DTORCH_MLIR_ENABLE_STABLEHLO=OFF \
    -DTORCH_MLIR_ENABLE_TOSA=OFF \
    -DTORCH_MLIR_ENABLE_REFBACKEND=OFF \
    -DTORCH_MLIR_ENABLE_PYTORCH_EXTENSIONS=OFF \
    -DMLIR_ENABLE_BINDINGS_PYTHON=ON \
    -DMLIR_ENABLE_PYTHON_STABLE_ABI=OFF \
    -DMLIR_BINDINGS_PYTHON_NB_DOMAIN=torch_mlir \
    -DCMAKE_C_FLAGS="${CFLAGS:-} ${EMCC_CFLAGS} -fwasm-exceptions -mno-tail-call" \
    -DCMAKE_CXX_FLAGS="${CXXFLAGS:-} ${EMCC_CFLAGS} -fwasm-exceptions -mno-tail-call" \
    -DCMAKE_EXE_LINKER_FLAGS="${LDFLAGS:-} -mno-tail-call -fwasm-exceptions -sMODULARIZE=1 -sEXPORT_ES6=1 -sALLOW_MEMORY_GROWTH=1 -sINITIAL_MEMORY=64MB -sSTACK_SIZE=8MB -sEXIT_RUNTIME=1" \
    -DPython3_EXECUTABLE="${PYTHON}" \
    -DPython3_INCLUDE_DIR="${PREFIX}/include/python${PY_VER}" \
    -DPython3_LIBRARY="${PREFIX}/lib/libpython${PY_VER}.a" \
    -DPython_EXECUTABLE="${PYTHON}" \
    -DPython_INCLUDE_DIR="${PREFIX}/include/python${PY_VER}" \
    -DPython_LIBRARY="${PREFIX}/lib/libpython${PY_VER}.a" \
    -DNB_SUFFIX="${TARGET_EXT_SUFFIX}" \
    -Dnanobind_DIR="${NANOBIND_CMAKE_DIR}"

emmake make -C build -j${CPU_COUNT:-4} TorchMLIRPythonModules TorchMLIRCAPI
cmake --install build --component TorchMLIRPythonModules
cmake --install build --component torch-mlir-headers

for archive in build/lib/libTorchMLIR*.a; do
    component=$(basename "${archive}" .a)
    cmake --install build --component "${component#lib}"
done

mkdir -p "${SP_DIR}"
mv "${PREFIX}/python_packages/torch_mlir/torch_mlir" "${SP_DIR}/torch_mlir"
rmdir "${PREFIX}/python_packages/torch_mlir" "${PREFIX}/python_packages"

# Give the browser filesystem ordinary packages instead of namespace packages.
touch "${SP_DIR}/torch_mlir/__init__.py" \
      "${SP_DIR}/torch_mlir/dialects/__init__.py" \
      "${SP_DIR}/torch_mlir/extras/__init__.py"

#!/bin/bash
set -euxo pipefail

NANOBIND_CMAKE_DIR=$("${BUILD_PREFIX}/bin/python3" -m nanobind --cmake_dir)
TARGET_EXT_SUFFIX=$("${PYTHON}" -c 'import sysconfig; print(sysconfig.get_config_var("EXT_SUFFIX"))')
CLANG_RESOURCE_DIR=$("${BUILD_PREFIX}/bin/clang" -print-resource-dir)

cmake_args=()
for arg in ${CMAKE_ARGS}; do
    [[ "$arg" == -DPYTHON* ]] || cmake_args+=("$arg")
done

emcmake cmake "${cmake_args[@]}" -S . -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_SCAN_FOR_MODULES=OFF \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DBUILD_SHARED_LIBS=OFF \
    -DLLVM_DIR="${PREFIX}/lib/cmake/llvm" \
    -DMLIR_DIR="${PREFIX}/lib/cmake/mlir" \
    -DLLD_DIR="${PREFIX}/lib/cmake/lld" \
    -DClang_DIR="${PREFIX}/lib/cmake/clang" \
    -DMLIR_TABLEGEN_EXE="${BUILD_PREFIX}/bin/mlir-tblgen" \
    -DMLIR_BUILDER_TABLEGEN="${BUILD_PREFIX}/bin/mlir_builder_tblgen" \
    -DMLIR_BUILDER_TABLEGEN_EXE="${BUILD_PREFIX}/bin/mlir_builder_tblgen" \
    -DIREE_HOST_BIN_DIR="${BUILD_PREFIX}/bin" \
    -DIREE_CLANG_BINARY="${BUILD_PREFIX}/bin/clang" \
    -DIREE_LLVM_LINK_BINARY="${BUILD_PREFIX}/bin/llvm-link" \
    -DIREE_CLANG_BUILTIN_HEADERS_PATH="${CLANG_RESOURCE_DIR}/include" \
    -DIREE_BUILD_BUNDLED_LLVM=OFF \
    -DIREE_BUILD_COMPILER=ON \
    -DIREE_BUILD_PYTHON_BINDINGS=ON \
    -DIREE_BUILD_RUNTIME_PYTHON_BINDINGS=ON \
    -DIREE_BUILD_RUNTIME_PYTHON_TOOLS=OFF \
    -DIREE_BUILD_COMPILER_PYTHON_TOOLS=OFF \
    -DIREE_ENABLE_PYTHON_STABLE_ABI=OFF \
    -DMLIR_ENABLE_PYTHON_STABLE_ABI=OFF \
    -DMLIR_BINDINGS_PYTHON_NB_DOMAIN=iree_compiler \
    -DIREE_USE_SYSTEM_DEPS=ON \
    -DIREE_BUILD_TESTS=OFF \
    -DIREE_BUILD_SAMPLES=OFF \
    -DIREE_BUILD_BENCHMARKS=OFF \
    -DIREE_ENABLE_THREADING=OFF \
    -DIREE_SYNCHRONIZATION_DISABLE_UNSAFE=ON \
    -DIREE_ERROR_ON_MISSING_SUBMODULES=OFF \
    -DIREE_ENABLE_WERROR_FLAG=OFF \
    -DIREE_TARGET_BACKEND_DEFAULTS=OFF \
    -DIREE_TARGET_BACKEND_LLVM_CPU=ON \
    -DIREE_TARGET_BACKEND_LLVM_CPU_WASM=ON \
    -DIREE_TARGET_BACKEND_WEBGPU_SPIRV=ON \
    -DIREE_INPUT_TORCH=ON \
    -DIREE_INPUT_STABLEHLO=ON \
    -DSTABLEHLO_ENABLE_TESTS=OFF \
    -DIREE_INPUT_TOSA=OFF \
    -DIREE_OUTPUT_FORMAT_C=OFF \
    -DIREE_HAL_DRIVER_DEFAULTS=OFF \
    -DIREE_HAL_DRIVER_LOCAL_SYNC=ON \
    -DIREE_HAL_DRIVER_LOCAL_TASK=OFF \
    -DIREE_HAL_EXECUTABLE_LOADER_SYSTEM_LIBRARY=ON \
    -DIREE_HAL_EXECUTABLE_LOADER_EMBEDDED_ELF=OFF \
    -DIREE_CMAKE_PLUGIN_PATHS="${SRC_DIR}/build_tools/emscripten" \
    -DIREE_EXTERNAL_HAL_DRIVERS=webgpu \
    -DFETCHCONTENT_FULLY_DISCONNECTED=ON \
    -DFETCHCONTENT_SOURCE_DIR_DAWN="${SRC_DIR}/third_party/dawn" \
    -DFETCHCONTENT_SOURCE_DIR_ABSEIL="${SRC_DIR}/third_party/abseil" \
    -DFETCHCONTENT_SOURCE_DIR_SPIRV-HEADERS="${SRC_DIR}/third_party/spirv-headers" \
    -DFETCHCONTENT_SOURCE_DIR_SPIRV-TOOLS="${SRC_DIR}/third_party/spirv-tools" \
    -DDAWN_JINJA2_DIR="${BUILD_PREFIX}/lib/python${PY_VER}/site-packages/jinja2" \
    -DDAWN_MARKUPSAFE_DIR="${BUILD_PREFIX}/lib/python${PY_VER}/site-packages/markupsafe" \
    -DCMAKE_C_FLAGS="${CFLAGS:-} ${EMCC_CFLAGS} -fwasm-exceptions -mno-tail-call -DIREE_FILE_IO_ENABLE=1" \
    -DCMAKE_CXX_FLAGS="${CXXFLAGS:-} ${EMCC_CFLAGS} -fwasm-exceptions -mno-tail-call -DIREE_FILE_IO_ENABLE=1" \
    -DPython3_EXECUTABLE="${PYTHON}" \
    -DPython3_INCLUDE_DIR="${PREFIX}/include/python${PY_VER}" \
    -DPython3_LIBRARY="${PREFIX}/lib/libpython${PY_VER}.a" \
    -DPython3_NumPy_INCLUDE_DIR="${SP_DIR}/numpy/_core/include" \
    -DPython_EXECUTABLE="${PYTHON}" \
    -DPython_INCLUDE_DIR="${PREFIX}/include/python${PY_VER}" \
    -DPython_LIBRARY="${PREFIX}/lib/libpython${PY_VER}.a" \
    -DPython_NumPy_INCLUDE_DIR="${SP_DIR}/numpy/_core/include" \
    -DNB_SUFFIX="${TARGET_EXT_SUFFIX}" \
    -Dnanobind_DIR="${NANOBIND_CMAKE_DIR}"

emmake ninja -C build -j${CPU_COUNT:-4} \
    iree_compiler_API_SharedImpl IREECompilerPythonModules \
    IREECompilerBuildPythonModules iree_runtime_bindings_python_PyExtRt

for component in IREECompilerPythonModules IREECompilerBuildPythonModules IreePythonPackage-runtime; do
    command cmake --install build --component "$component" --prefix "${SRC_DIR}/build/install"
done

mkdir -p "${SP_DIR}/iree"
cp -a build/install/python_packages/iree_compiler/iree/. "${SP_DIR}/iree/"
cp -a build/install/python_packages/iree_runtime/iree/. "${SP_DIR}/iree/"

printf 'PACKAGE_SUFFIX = ""\nVERSION = "%s"\nREVISIONS = {"IREE": "%s"}\n' \
    "${IREE_PACKAGE_VERSION}" "${IREE_SOURCE_REVISION}" > "${SP_DIR}/iree/_runtime_libs/version.py"
touch "${SP_DIR}/iree/_runtime_libs/__init__.py"

install -m 644 build/lib/libIREECompiler.so "${SP_DIR}/iree/compiler/_mlir_libs/"

touch "${SP_DIR}/iree/__init__.py" \
      "${SP_DIR}/iree/compiler/dialects/__init__.py" \
      "${SP_DIR}/iree/compiler/extras/__init__.py"

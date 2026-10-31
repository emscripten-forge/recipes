#!/bin/bash
set -euxo pipefail

NANOBIND_CMAKE_DIR=$("${BUILD_PREFIX}/bin/python3" -m nanobind --cmake_dir)
TARGET_EXT_SUFFIX=$("${PYTHON}" -c 'import sysconfig; print(sysconfig.get_config_var("EXT_SUFFIX"))')

cmake_args=()
for arg in ${CMAKE_ARGS}; do
    [[ "$arg" == -DPYTHON* ]] || cmake_args+=("$arg")
done

emcmake cmake "${cmake_args[@]}" -S . -B build -G "Unix Makefiles" \
    -DCMAKE_BUILD_TYPE=Release \
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
    -DIREE_BUILD_BUNDLED_LLVM=OFF \
    -DIREE_BUILD_COMPILER=ON \
    -DIREE_BUILD_PYTHON_BINDINGS=ON \
    -DIREE_BUILD_RUNTIME_PYTHON_BINDINGS=OFF \
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
    -DIREE_TARGET_BACKEND_LLVM_CPU=OFF \
    -DIREE_TARGET_BACKEND_WEBGPU_SPIRV=ON \
    -DIREE_INPUT_TORCH=ON \
    -DIREE_INPUT_STABLEHLO=ON \
    -DSTABLEHLO_ENABLE_TESTS=OFF \
    -DIREE_INPUT_TOSA=OFF \
    -DIREE_OUTPUT_FORMAT_C=OFF \
    -DIREE_HAL_DRIVER_DEFAULTS=OFF \
    -DFETCHCONTENT_FULLY_DISCONNECTED=ON \
    -DFETCHCONTENT_SOURCE_DIR_DAWN="${SRC_DIR}/third_party/dawn" \
    -DFETCHCONTENT_SOURCE_DIR_ABSEIL="${SRC_DIR}/third_party/abseil" \
    -DFETCHCONTENT_SOURCE_DIR_SPIRV-HEADERS="${SRC_DIR}/third_party/spirv-headers" \
    -DFETCHCONTENT_SOURCE_DIR_SPIRV-TOOLS="${SRC_DIR}/third_party/spirv-tools" \
    -DDAWN_JINJA2_DIR="${BUILD_PREFIX}/lib/python${PY_VER}/site-packages/jinja2" \
    -DDAWN_MARKUPSAFE_DIR="${BUILD_PREFIX}/lib/python${PY_VER}/site-packages/markupsafe" \
    -DCMAKE_C_FLAGS="${CFLAGS:-} ${EMCC_CFLAGS} -fwasm-exceptions -mno-tail-call" \
    -DCMAKE_CXX_FLAGS="${CXXFLAGS:-} ${EMCC_CFLAGS} -fwasm-exceptions -mno-tail-call" \
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

emmake make -C build -j${CPU_COUNT:-4} iree_compiler_API_SharedImpl
emmake make -C build -j${CPU_COUNT:-4} \
    install-IREECompilerPythonModules install-IREECompilerBuildPythonModules

mkdir -p "${SP_DIR}"
mv "${PREFIX}/python_packages/iree_compiler/iree" "${SP_DIR}/iree"
rmdir "${PREFIX}/python_packages/iree_compiler" "${PREFIX}/python_packages"
install -m 644 build/lib/libIREECompiler.so "${SP_DIR}/iree/compiler/_mlir_libs/"

touch "${SP_DIR}/iree/__init__.py" \
      "${SP_DIR}/iree/compiler/dialects/__init__.py" \
      "${SP_DIR}/iree/compiler/extras/__init__.py"

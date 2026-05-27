#!/bin/bash
set -euo pipefail

export CFLAGS="${CFLAGS:-} ${EMCC_CFLAGS:-} -Wno-pass-failed"
export CXXFLAGS="${CXXFLAGS:-} ${EMCC_CFLAGS:-} -Wno-pass-failed"

# ORT cmake entry point is in the cmake/ subdirectory
emcmake cmake -S cmake -B build \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -Donnxruntime_BUILD_WEBASSEMBLY=ON \
    -Donnxruntime_BUILD_WEBASSEMBLY_STATIC_LIB=ON \
    -Donnxruntime_ENABLE_WEBASSEMBLY_SIMD=ON \
    -Donnxruntime_ENABLE_WEBASSEMBLY_THREADS=OFF \
    -Donnxruntime_USE_WEBGPU=ON \
    -Donnxruntime_USE_WEBNN=OFF \
    -Donnxruntime_DISABLE_WASM_EXCEPTION_CATCHING=ON \
    -Donnxruntime_ENABLE_RTTI=OFF \
    -Donnxruntime_BUILD_UNIT_TESTS=OFF \
    -Donnxruntime_BUILD_BENCHMARKS=OFF \
    -Donnxruntime_USE_FULL_PROTOBUF=OFF \
    -Donnxruntime_WGSL_TEMPLATE=static \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DFETCHCONTENT_QUIET=OFF

emmake ninja -C build -j"${CPU_COUNT}"

# cd build
# ninja install

#Install static library
mkdir -p "${PREFIX}/lib"
cp build/libonnxruntime_webassembly.a "${PREFIX}/lib/"

echo "✅ onnxruntime-wasm build complete ✅"

# Install C/C++ API headers per the ORT wasm static lib documentation:
# https://onnxruntime.ai/docs/build/web.html
mkdir -p "${PREFIX}/include/onnxruntime"

#copy all public headers
cp -r include/onnxruntime/. "${PREFIX}/include/onnxruntime/"

echo "✅ onnxruntime-wasm headers installed ✅"

# Install the vendored emdawnwebgpu package used by the WebGPU provider so
# downstream consumers can link the same runtime glue expected by ORT.
EMDAWN_SRC_ROOT="build/_deps/dawn-src"
EMDAWN_GEN_ROOT="build/_deps/dawn-build/gen/src/emdawnwebgpu"
EMDAWN_PREFIX="${PREFIX}/share/emdawnwebgpu"

mkdir -p "${EMDAWN_PREFIX}/webgpu/src"
mkdir -p "${EMDAWN_PREFIX}/webgpu/include/webgpu"
mkdir -p "${EMDAWN_PREFIX}/webgpu/include/dawn"
mkdir -p "${EMDAWN_PREFIX}/webgpu_cpp/include/webgpu"
mkdir -p "${EMDAWN_PREFIX}/webgpu_cpp/include/dawn"

cp "${EMDAWN_SRC_ROOT}/src/emdawnwebgpu/pkg/emdawnwebgpu.port.py" "${EMDAWN_PREFIX}/"
cp "${EMDAWN_SRC_ROOT}/src/emdawnwebgpu/pkg/README.md" "${EMDAWN_PREFIX}/"
cp "${EMDAWN_SRC_ROOT}/third_party/emdawnwebgpu/pkg/webgpu/src/webgpu.cpp" "${EMDAWN_PREFIX}/webgpu/src/"
cp "${EMDAWN_SRC_ROOT}/third_party/emdawnwebgpu/pkg/webgpu/src/library_webgpu.js" "${EMDAWN_PREFIX}/webgpu/src/"
cp "${EMDAWN_SRC_ROOT}/third_party/emdawnwebgpu/pkg/webgpu/src/webgpu-externs.js" "${EMDAWN_PREFIX}/webgpu/src/"
cp "${EMDAWN_SRC_ROOT}/third_party/emdawnwebgpu/pkg/webgpu/src/LICENSE" "${EMDAWN_PREFIX}/webgpu/src/"
cp "${EMDAWN_GEN_ROOT}/library_webgpu_enum_tables.js" "${EMDAWN_PREFIX}/webgpu/src/"
cp "${EMDAWN_GEN_ROOT}/library_webgpu_generated_sig_info.js" "${EMDAWN_PREFIX}/webgpu/src/"
cp "${EMDAWN_GEN_ROOT}/library_webgpu_generated_struct_info.js" "${EMDAWN_PREFIX}/webgpu/src/"
cp "${EMDAWN_GEN_ROOT}/include/webgpu/"* "${EMDAWN_PREFIX}/webgpu/include/webgpu/"
cp "${EMDAWN_GEN_ROOT}/include/dawn/webgpu_cpp_print.h" "${EMDAWN_PREFIX}/webgpu/include/dawn/"
cp "${EMDAWN_GEN_ROOT}/include/webgpu/webgpu_cpp.h" "${EMDAWN_PREFIX}/webgpu_cpp/include/webgpu/"
cp "${EMDAWN_GEN_ROOT}/include/webgpu/webgpu_cpp_chained_struct.h" "${EMDAWN_PREFIX}/webgpu_cpp/include/webgpu/"
cp "${EMDAWN_GEN_ROOT}/include/webgpu/webgpu_enum_class_bitmasks.h" "${EMDAWN_PREFIX}/webgpu_cpp/include/webgpu/"
cp "${EMDAWN_GEN_ROOT}/include/webgpu/webgpu_glfw.h" "${EMDAWN_PREFIX}/webgpu_cpp/include/webgpu/"
cp "${EMDAWN_GEN_ROOT}/include/dawn/webgpu_cpp_print.h" "${EMDAWN_PREFIX}/webgpu_cpp/include/dawn/"

echo "✅ emdawnwebgpu package installed ✅"

# Install CMake config so consumers can use find_package(onnxruntime-wasm)
mkdir -p "${PREFIX}/lib/cmake/onnxruntime-wasm"
cat > "${PREFIX}/lib/cmake/onnxruntime-wasm/onnxruntime-wasmConfig.cmake" <<EOF
# onnxruntime-wasmConfig.cmake
# CMake configuration file for onnxruntime-wasm (static WebAssembly build)
#
# Usage in consumer CMakeLists.txt:
#
#   find_package(onnxruntime-wasm REQUIRED)
#   target_link_libraries(my_target PRIVATE onnxruntime::onnxruntime_webassembly)
#
# This will automatically bring in the include directories and the Emscripten
# link options needed to build a working WASM binary.

cmake_minimum_required(VERSION 3.20)

# Compute the installation prefix from this file's location.

get_filename_component(_ORT_IMPORT_PREFIX "\${CMAKE_CURRENT_LIST_FILE}" PATH)
get_filename_component(_ORT_IMPORT_PREFIX "\${_ORT_IMPORT_PREFIX}" PATH)
get_filename_component(_ORT_IMPORT_PREFIX "\${_ORT_IMPORT_PREFIX}" PATH)
get_filename_component(_ORT_IMPORT_PREFIX "\${_ORT_IMPORT_PREFIX}" PATH)

set(_ORT_LIB "\${_ORT_IMPORT_PREFIX}/lib/libonnxruntime_webassembly.a")
set(_ORT_INCLUDE_DIR "\${_ORT_IMPORT_PREFIX}/include")
set(_ORT_EMDAWNWEBGPU_PORT "\${_ORT_IMPORT_PREFIX}/share/emdawnwebgpu/emdawnwebgpu.port.py")

if(NOT EXISTS "\${_ORT_LIB}")
    set(onnxruntime-wasm_FOUND FALSE)
    if(onnxruntime-wasm_FIND_REQUIRED)
        message(FATAL_ERROR "onnxruntime-wasm: library not found at \${_ORT_LIB}")
    elseif(NOT onnxruntime-wasm_FIND_QUIETLY)
        message(WARNING "onnxruntime-wasm: library not found at \${_ORT_LIB}")
    endif()
    return()
endif()

if(NOT TARGET onnxruntime::onnxruntime_webassembly)
    add_library(onnxruntime::onnxruntime_webassembly STATIC IMPORTED)

    set_target_properties(onnxruntime::onnxruntime_webassembly PROPERTIES
        IMPORTED_LOCATION "\${_ORT_LIB}"
        INTERFACE_INCLUDE_DIRECTORIES "\${_ORT_INCLUDE_DIR}"
    )

    if(EMSCRIPTEN)
        set(_ORT_WEBGPU_LINK_OPTION -sUSE_WEBGPU=1)
        if(EXISTS "\${_ORT_EMDAWNWEBGPU_PORT}")
            set(_ORT_WEBGPU_LINK_OPTION "--use-port=\${_ORT_EMDAWNWEBGPU_PORT}")
        elseif(DEFINED EMSCRIPTEN_VERSION AND EMSCRIPTEN_VERSION VERSION_GREATER_EQUAL "4.0.10")
            set(_ORT_WEBGPU_LINK_OPTION --use-port=emdawnwebgpu)
        endif()

        set_property(TARGET onnxruntime::onnxruntime_webassembly APPEND PROPERTY
            INTERFACE_LINK_OPTIONS
                -msimd128
                \${_ORT_WEBGPU_LINK_OPTION}
                -sALLOW_MEMORY_GROWTH=1
                -sINITIAL_MEMORY=64MB
                -sEXIT_RUNTIME=1
        )
    endif()
endif()

set(onnxruntime-wasm_VERSION "${PKG_VERSION}")
set(ONNXRUNTIME_WASM_VERSION "${PKG_VERSION}")

set(onnxruntime-wasm_FOUND TRUE)
set(ONNXRUNTIME_WASM_FOUND TRUE)
set(ONNXRUNTIME_WASM_INCLUDE_DIRS "\${_ORT_INCLUDE_DIR}")
set(ONNXRUNTIME_WASM_LIBRARIES    "\${_ORT_LIB}")

unset(_ORT_IMPORT_PREFIX)
unset(_ORT_LIB)
unset(_ORT_INCLUDE_DIR)
unset(_ORT_EMDAWNWEBGPU_PORT)
unset(_ORT_WEBGPU_LINK_OPTION)
EOF

echo "✅ onnxruntime-wasm CMake config installed ✅"

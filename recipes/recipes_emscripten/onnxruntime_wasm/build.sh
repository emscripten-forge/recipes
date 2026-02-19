#!/bin/bash
set -euo pipefail

export CFLAGS="${CFLAGS:-} ${EMCC_CFLAGS:-}"
export CXXFLAGS="${CXXFLAGS:-} ${EMCC_CFLAGS:-}"

# ORT cmake entry point is in the cmake/ subdirectory
emcmake cmake -S cmake -B build \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -Donnxruntime_BUILD_WEBASSEMBLY=ON \
    -Donnxruntime_BUILD_WEBASSEMBLY_STATIC_LIB=ON \
    -Donnxruntime_ENABLE_WEBASSEMBLY_SIMD=ON \
    -Donnxruntime_ENABLE_WEBASSEMBLY_THREADS=OFF \
    -Donnxruntime_USE_WEBGPU=OFF \
    -Donnxruntime_USE_WEBNN=OFF \
    -Donnxruntime_DISABLE_WASM_EXCEPTION_CATCHING=ON \
    -Donnxruntime_ENABLE_RTTI=OFF \
    -Donnxruntime_BUILD_UNIT_TESTS=OFF \
    -Donnxruntime_BUILD_BENCHMARKS=OFF \
    -Donnxruntime_USE_FULL_PROTOBUF=OFF \
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
cp include/onnxruntime/core/session/onnxruntime_c_api.h        "${PREFIX}/include/onnxruntime/"
cp include/onnxruntime/core/session/onnxruntime_cxx_api.h      "${PREFIX}/include/onnxruntime/"
cp include/onnxruntime/core/session/onnxruntime_cxx_inline.h   "${PREFIX}/include/onnxruntime/"

echo "✅ onnxruntime-wasm headers installed ✅"

# Install CMake config so consumers can use find_package(onnxruntime-wasm)
mkdir -p "${PREFIX}/lib/cmake/onnxruntime-wasm"
sed "s/@VERSION@/${PKG_VERSION}/g" "${RECIPE_DIR}/onnxruntime-wasmConfig.cmake" \
    > "${PREFIX}/lib/cmake/onnxruntime-wasm/onnxruntime-wasmConfig.cmake"

echo "✅ onnxruntime-wasm CMake config installed ✅"

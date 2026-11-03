#!/bin/bash
set -euo pipefail

# Arrow C++ as static libraries; mirrors upstream's `features-emscripten`
# CMake preset (no threading, no SIMD, no jemalloc/mimalloc) but takes the
# dependencies from the host environment instead of bundling them.
ARROW_CPP_OPTIONS=(
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DCMAKE_PREFIX_PATH=${PREFIX}"
    "-DCMAKE_INSTALL_PREFIX=${PREFIX}"
    "-DCMAKE_C_BYTE_ORDER=LITTLE_ENDIAN"

    "-DARROW_BUILD_SHARED=OFF"
    "-DARROW_BUILD_STATIC=ON"
    "-DARROW_BUILD_TESTS=OFF"
    "-DARROW_ENABLE_TIMING_TESTS=OFF"
    "-DARROW_ENABLE_THREADING=OFF"
    "-DARROW_SIMD_LEVEL=NONE"
    "-DARROW_RUNTIME_SIMD_LEVEL=NONE"
    "-DARROW_JEMALLOC=OFF"
    "-DARROW_MIMALLOC=OFF"
    "-DARROW_DEPENDENCY_SOURCE=SYSTEM"
    "-DARROW_DEPENDENCY_USE_SHARED=OFF"

    "-DARROW_ACERO=ON"
    "-DARROW_COMPUTE=ON"
    "-DARROW_CSV=ON"
    "-DARROW_DATASET=ON"
    "-DARROW_FILESYSTEM=ON"
    "-DARROW_IPC=ON"
    "-DARROW_JSON=ON"
    "-DARROW_PARQUET=ON"
    "-DPARQUET_REQUIRE_ENCRYPTION=OFF"
    "-DARROW_WITH_RE2=ON"
    "-DARROW_WITH_UTF8PROC=ON"

    # simdjson (JSON reader) and uriparser (filesystem URIs) have no
    # emscripten-forge packages: let Arrow build its pinned copies
    "-Dsimdjson_SOURCE=BUNDLED"
    "-DSIMDJSON_ENABLE_THREADS=OFF"
    "-Duriparser_SOURCE=BUNDLED"

    "-DARROW_WITH_BROTLI=ON"
    "-DARROW_WITH_BZ2=ON"
    "-DARROW_WITH_LZ4=ON"
    "-DARROW_WITH_SNAPPY=ON"
    "-DARROW_WITH_ZLIB=ON"
    "-DARROW_WITH_ZSTD=ON"

    "-DARROW_SUBSTRAIT=OFF"
    "-DARROW_CUDA=OFF"
    "-DARROW_FLIGHT=OFF"
    "-DARROW_GANDIVA=OFF"
    "-DARROW_ORC=OFF"
    "-DARROW_AZURE=OFF"
    "-DARROW_GCS=OFF"
    "-DARROW_S3=OFF"
    "-DARROW_WITH_OPENTELEMETRY=OFF"

    "-DBoost_ROOT=${PREFIX}"
    "-DBrotli_ROOT=${PREFIX}"
    "-DBROTLI_ROOT=${PREFIX}"
    "-DBrotliAlt_ROOT=${PREFIX}"
    "-DBROTLI_COMMON_LIBRARY=${PREFIX}/lib/libbrotlicommon.a"
    "-DBROTLI_ENC_LIBRARY=${PREFIX}/lib/libbrotlienc.a"
    "-DBROTLI_DEC_LIBRARY=${PREFIX}/lib/libbrotlidec.a"
    "-DBROTLI_INCLUDE_DIR=${PREFIX}/include"
    "-DBZip2_ROOT=${PREFIX}"
    "-DBZIP2_LIBRARIES=${PREFIX}/lib/libbz2.a"
    "-DBZIP2_LIBRARY=${PREFIX}/lib/libbz2.a"
    "-DBZIP2_INCLUDE_DIR=${PREFIX}/include"
    "-Dlz4_ROOT=${PREFIX}"
    "-Dlz4_DIR=${PREFIX}/lib/cmake/lz4"
    "-Dre2_ROOT=${PREFIX}"
    "-Dre2_DIR=${PREFIX}/lib/cmake/re2"
    "-DZLIB_ROOT=${PREFIX}"
    "-DZLIB_LIBRARY=${PREFIX}/lib/libz.a"
    "-DZLIB_INCLUDE_DIR=${PREFIX}/include"
    "-Dabsl_ROOT=${PREFIX}"
    "-Dabsl_DIR=${PREFIX}/lib/cmake/absl"
    "-Dnlohmann_json_ROOT=${PREFIX}"
    "-Dzstd_ROOT=${PREFIX}"
    "-DZSTD_ROOT=${PREFIX}"
    "-DZSTD_LIB=${PREFIX}/lib/libzstd.a"
    "-DZSTD_INCLUDE_DIR=${PREFIX}/include"
    "-DRapidJSON_ROOT=${PREFIX}"
    "-Dxsimd_ROOT=${PREFIX}"
    "-DThrift_DIR=${PREFIX}/lib/cmake/thrift"
    "-DThrift_ROOT=${PREFIX}"
    "-DSnappy_ROOT=${PREFIX}"
    "-DSnappy_DIR=${PREFIX}/lib/cmake/Snappy"
    "-Dutf8proc_LIB=${PREFIX}/lib/libutf8proc.a"
    "-Dutf8proc_INCLUDE_DIR=${PREFIX}/include"
)

export CXXFLAGS="${CXXFLAGS:-} -fms-extensions"

mkdir -p build_cpp
cd build_cpp

emcmake cmake ${CMAKE_ARGS} \
    "${ARROW_CPP_OPTIONS[@]}" \
    -S ../cpp \
    -B ./

emmake make install -j"${CPU_COUNT:-4}"

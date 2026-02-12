#!/usr/bin/env nu

# ============================================================================
# Common CMake Configuration
# ============================================================================

# Common CMake settings for all builds
let CMAKE_COMMON_ARGS = [
    # $"-DCMAKE_PREFIX_PATH:PATH=($env.PREFIX)"
    # $"-DCMAKE_INSTALL_PREFIX:PATH=($env.PREFIX)"
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DCMAKE_BUILD_TYPE=Release"
]

# Arrow feature flags (used by both Arrow C++ and PyArrow)
let ARROW_FEATURES = [
    "-DARROW_SIMD_LEVEL=AVX2"
    "-DARROW_RUNTIME_SIMD_LEVEL=AVX2"
    "-DARROW_BUILD_SHARED=OFF"
    "-DARROW_BUILD_TESTS=OFF"
    "-DARROW_ENABLE_TIMING_TESTS=OFF"
    "-DARROW_ENABLE_THREADING=OFF"
    "-DARROW_JEMALLOC=OFF"
    "-DARROW_MIMALLOC=OFF"
    # Enable features
    "-DARROW_COMPUTE=ON"
    "-DARROW_CSV=ON"
    "-DARROW_JSON=ON"
    "-DARROW_FILESYSTEM=ON"
    "-DARROW_DATASET=ON"
    "-DARROW_ACERO=ON"
    "-DARROW_WITH_UTF8PROC=OFF"
    "-DARROW_WITH_RE2=ON"
    "-DARROW_IPC=ON"
    "-DARROW_WITH_BROTLI=ON"
    "-DARROW_WITH_SNAPPY=ON"
    "-DARROW_WITH_BZ2=ON"
    "-DARROW_WITH_LZ4=ON"
    "-DARROW_WITH_ZLIB=ON"
    "-DARROW_WITH_ZSTD=ON"
    # Enable Parquet with bundled Thrift
    "-DARROW_PARQUET=ON"
    "-DARROW_DEPENDENCY_SOURCE=AUTO"
    "-DARROW_THRIFT_USE_SHARED=OFF"
    # Disable features (Substrait requires Boost setup, BZ2 has CMake issues)
    $"-DBoost_ROOT=($env.PREFIX)"
    $"-DBrotli_ROOT=($env.PREFIX)"
    $"-DBROTLI_ROOT=($env.PREFIX)"
    $"-DBZip2_ROOT=($env.PREFIX)"
    $"-Dlz4Alt_ROOT=($env.PREFIX)"
    $"-Dre2_ROOT=($env.PREFIX)"
    $"-DZLIB_ROOT=($env.PREFIX)"
    $"-Dabsl_ROOT=($env.PREFIX)"
    $"-Dnlohmann_json_ROOT=($env.PREFIX)"
    $"-DProtobuf_ROOT=($env.PREFIX)"
    $"-Dzstd_ROOT=($env.PREFIX)"
    $"-Dxsimd_ROOT=($env.PREFIX)"
    $"-DRapidJSON_ROOT=($env.PREFIX)"
    # "-DARROW_WITH_BOOST=OFF"
    "-DSnappy_SOURCE=BUNDLED"
    "-DARROW_SUBSTRAIT=OFF"
    "-DARROW_CUDA=OFF"
    "-DARROW_FLIGHT=OFF"
    "-DARROW_GANDIVA=OFF"
    "-DARROW_ORC=OFF"
    "-DARROW_AZURE=OFF"
    "-DARROW_GCS=OFF"
]

# ============================================================================
# Build Arrow C++ with all features (except CUDA)
# ============================================================================

mkdir build_cpp
cd build_cpp

# Add Emscripten-specific flags to help Boost detect the platform correctly
$env.CXXFLAGS = $"($env.CXXFLAGS? | default '') -fms-extensions -pthread"

$env.LDFLAGS = $"($env.LDFLAGS? | default '') -sNODERAWFS=1 -sUSE_ZLIB=1 -sFORCE_FILESYSTEM=1 -sALLOW_MEMORY_GROWTH=1 -sEXPORTED_RUNTIME_METHODS=FS,PATH,ERRNO_CODES,PROXYFS -lproxyfs.js"

# Configure Arrow C++ with comprehensive feature set
let cpu_count = ($env.CPU_COUNT? | default "8")
let cmake_args = ($env.CMAKE_ARGS? | default "" | split row ' ' | where $it != "")

cmake ...[
    ...$cmake_args
    ...$CMAKE_COMMON_ARGS
    ...$ARROW_FEATURES
    "-DARROW_INSTALL_NAME_RPATH=ON"
    $"-Dutf8proc_LIB=($env.PREFIX)/lib/libutf8proc.a"
    $"-Dutf8proc_INCLUDE_DIR=($env.PREFIX)/include"
    $"-DRapidJSON_DIR=($env.PREFIX)/lib/cmake/RapidJSON/"
    "-DCMAKE_C_COMPILER_LAUNCHER=sccache"
    "-DCMAKE_CXX_COMPILER_LAUNCHER=sccache"
    $"-DCMAKE_PREFIX_PATH=($env.PREFIX)"
    $"-DCMAKE_INSTALL_PREFIX=($env.PREFIX)"
    "-S" "../cpp"
    "-B" "./"
]

# Build and install Arrow C++
emmake make install $"-j($cpu_count)"


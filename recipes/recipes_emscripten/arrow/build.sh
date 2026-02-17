#!/bin/bash
set -euo pipefail

COMMON_CMAKE_OPTIONS=(
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DCMAKE_BUILD_TYPE=Release"
)

ARROW_SHARED_FEATURES=(
    "-DARROW_BUILD_SHARED=OFF"
    "-DARROW_BUILD_TESTS=OFF"
    "-DARROW_ENABLE_TIMING_TESTS=OFF"
    "-DARROW_COMPUTE=ON"
    "-DARROW_CSV=ON"
    "-DARROW_JSON=ON"
    "-DARROW_FILESYSTEM=ON"
    "-DARROW_DATASET=ON"
    "-DARROW_PARQUET=ON"
    "-DARROW_WITH_RE2=ON"
    "-DARROW_SIMD_LEVEL=AVX2"
    "-DARROW_RUNTIME_SIMD_LEVEL=AVX2"
    "-DARROW_ENABLE_THREADING=OFF"
    "-DARROW_JEMALLOC=OFF"
    "-DARROW_MIMALLOC=OFF"
    "-DARROW_ACERO=ON"
    "-DARROW_WITH_UTF8PROC=ON"
    "-DARROW_IPC=ON"
    "-DARROW_WITH_BROTLI=ON"
    "-DARROW_DEPENDENCY_SOURCE=SYSTEM"
    "-DARROW_DEPENDENCY_USE_SHARED=OFF"
)

ARROW_DEPENDENCIES=(
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
    # "-DZLIB_DIR=${PREFIX}"
    "-DZLIB_ROOT=${PREFIX}"
    "-DZLIB_LIBRARY=${PREFIX}/lib/libz.a"
    "-DZLIB_INCLUDE_DIR=${PREFIX}/include"
    "-Dabsl_ROOT=${PREFIX}"
    "-Dnlohmann_json_ROOT=${PREFIX}"
    "-DProtobuf_ROOT=${PREFIX}"
    "-Dzstd_ROOT=${PREFIX}"
    "-DZSTD_ROOT=${PREFIX}"
    "-DZSTD_LIB=${PREFIX}/lib/libzstd.a"
    "-DZSTD_INCLUDE_DIR=${PREFIX}/include"
    "-Dxsimd_ROOT=${PREFIX}"
    "-DRapidJSON_ROOT=${PREFIX}"
    "-DThrift_DIR=${PREFIX}/lib/cmake/thrift"
    "-DThrift_ROOT=${PREFIX}"
    "-DSnappy_ROOT=${PREFIX}"
    "-DSnappy_DIR=${PREFIX}/lib/cmake/Snappy"
    "-Dre2_DIR=$PREFIX/lib/cmake/re2"
    "-Dutf8proc_LIB=$PREFIX/lib/libutf8proc.a"
    "-Dabsl_DIR=$PREFIX/lib/cmake/absl"
    "-Dutf8proc_INCLUDE_DIR=$PREFIX/include"
)

ARROW_SHARED_COMPRESSION=(
  "-DARROW_WITH_BZ2=ON"
  "-DARROW_WITH_LZ4=ON"
  "-DARROW_WITH_SNAPPY=ON"
  "-DARROW_WITH_ZLIB=ON"
  "-DARROW_WITH_ZSTD=ON"
)

ARROW_SHARED_DISABLED_BACKENDS=(
  "-DARROW_SUBSTRAIT=OFF"
  "-DARROW_CUDA=OFF"
  "-DARROW_FLIGHT=OFF"
  "-DARROW_GANDIVA=OFF"
  "-DARROW_ORC=OFF"
  "-DARROW_AZURE=OFF"
  "-DARROW_GCS=OFF"
)

ARROW_CPP_OPTIONS=(
    "${COMMON_CMAKE_OPTIONS[@]}"
    "${ARROW_SHARED_FEATURES[@]}"
    "${ARROW_SHARED_COMPRESSION[@]}"
    "${ARROW_SHARED_DISABLED_BACKENDS[@]}"
    "${ARROW_DEPENDENCIES[@]}"
)

build_arrow_cpp() {

  mkdir -p build_cpp
  cd build_cpp

  export CXXFLAGS="${CXXFLAGS:-} -fms-extensions"
  export LDFLAGS="${LDFLAGS:-} -sNODERAWFS=1 -sUSE_ZLIB=1 -sFORCE_FILESYSTEM=1 -sALLOW_MEMORY_GROWTH=1 -sEXPORTED_RUNTIME_METHODS=FS,PATH,ERRNO_CODES,PROXYFS -lproxyfs.js"

  cpu_count="${CPU_COUNT:-8}"
  read -r -a cmake_args <<< "${CMAKE_ARGS:-}"

  cmake \
    "${cmake_args[@]}" \
    "${COMMON_CMAKE_OPTIONS[@]}" \
    "${ARROW_CPP_OPTIONS[@]}" \
    "-DCMAKE_FIND_PACKAGE_PREFER_CONFIG=ON" \
    "-DARROW_INSTALL_NAME_RPATH=ON" \
    "-DCMAKE_PREFIX_PATH=${PREFIX}" \
    "-DCMAKE_INSTALL_PREFIX=${PREFIX}" \
    -S ../cpp \
    -B ./

  emmake make install -j"${cpu_count}"

  echo "✅ Arrow C++ build and installation complete ✅"
}

build_pyarrow() {
    echo "============================================================"    
    echo "🐍 Starting PyArrow build with Python ${PY_VER} 🐍"
    echo "============================================================"   

    ARROW_PYTHON_OPTIONS=(
        "-DPython3_INCLUDE_DIR=$PREFIX/include/python${PY_VER}"
        "-DPython3_INCLUDE_DIRS=$PREFIX/include/python${PY_VER}"
        "-DPython3_NumPy_INCLUDE_DIR=$BUILD_PREFIX/lib/python${PY_VER}/site-packages/numpy/_core/include"
        "-DPython3_NumPy_INCLUDE_DIRS=$BUILD_PREFIX/lib/python${PY_VER}/site-packages/numpy/_core/include"
        "-DPYARROW_WITH_COMPUTE=ON"
        "-DPYARROW_WITH_DATASET=ON"
        "-DPYARROW_WITH_ACERO=ON"
        "-DPYARROW_BUILD_PARQUET=ON"
        "-DPYARROW_WITH_PARQUET=ON"
        "-DPARQUET_REQUIRE_ENCRYPTION=OFF"
        "-DPYARROW_BUNDLE_ARROW_CPP=OFF"
        "-DPYARROW_BUNDLE_CYTHON_CPP=ON"
    )

    pyarrow_cmake_options=(
        "-DCMAKE_PREFIX_PATH:PATH=${PREFIX}"
        "-DCMAKE_INSTALL_PREFIX:PATH=${PREFIX}"
        "-DCMAKE_PLATFORM_NO_VERSIONED_SONAME=TRUE"
        "${ARROW_CPP_OPTIONS[@]}"
        "${ARROW_PYTHON_OPTIONS[@]}"
        "-DArrow_DIR=$PREFIX/lib/cmake/Arrow"
        "-DArrowDataset_DIR=$PREFIX/lib/cmake/ArrowDataset"
        "-DArrowCompute_DIR=$PREFIX/lib/cmake/ArrowCompute"
        "-DArrowAcero_DIR=$PREFIX/lib/cmake/ArrowAcero"
        "-DArrowParquet_DIR=$PREFIX/lib/cmake/ArrowParquet"
        "-DParquet_DIR=$PREFIX/lib/cmake/Parquet"
        "-DCMAKE_PROJECT_INCLUDE=$RECIPE_DIR/cmake/overwriteProp.cmake"
    )

    export PYARROW_CMAKE_OPTIONS="${pyarrow_cmake_options[*]}"
    export _PYTHON_SYSCONFIGDATA_NAME="_sysconfigdata__emscripten_wasm32-emscripten"

    export PYODIDE=1
    export PYTHONINCLUDE="$PREFIX/include/python$PY_VER"
    export CPYTHONLIB="$PREFIX/lib/libpython$PY_VER.a"
    export NUMPY_LIB="$PREFIX/lib/python$PY_VER/site-packages/numpy"
    export SYSCONFIG_NAME="_sysconfigdata__emscripten_wasm32-emscripten"
    export ARROW_HOME="$PREFIX"
    export INCLUDE_NUMPY_FLAGS="-I$PREFIX/lib/python${PY_VER}/site-packages/numpy/_core/include"

    sanitized_cflags=" ${CFLAGS:-} "
    sanitized_cflags="${sanitized_cflags// -pthread / }"
    sanitized_cflags="${sanitized_cflags// -sPTHREADS / }"
    sanitized_cflags="${sanitized_cflags// -sPTHREADS=1 / }"

    sanitized_cxxflags=" ${CXXFLAGS:-} "
    sanitized_cxxflags="${sanitized_cxxflags// -pthread / }"
    sanitized_cxxflags="${sanitized_cxxflags// -sPTHREADS / }"
    sanitized_cxxflags="${sanitized_cxxflags// -sPTHREADS=1 / }"

    sanitized_ldflags=" ${LDFLAGS:-} "
    sanitized_ldflags="${sanitized_ldflags// -pthread / }"
    sanitized_ldflags="${sanitized_ldflags// -sPTHREADS / }"
    sanitized_ldflags="${sanitized_ldflags// -sPTHREADS=1 / }"

    export CFLAGS="${sanitized_cflags} $EM_FORGE_SIDE_MODULE_CFLAGS $INCLUDE_NUMPY_FLAGS -sWASM_BIGINT"
    export CXXFLAGS="${sanitized_cxxflags} $EM_FORGE_SIDE_MODULE_CFLAGS $INCLUDE_NUMPY_FLAGS -sWASM_BIGINT"
    export PYARROW_CXXFLAGS="$EM_FORGE_SIDE_MODULE_CFLAGS $INCLUDE_NUMPY_FLAGS -sWASM_BIGINT"
    export LDFLAGS="${sanitized_ldflags} $EM_FORGE_SIDE_MODULE_LDFLAGS -sWASM_BIGINT -L$PREFIX/lib"
    export CMAKE_BUILD_PARALLEL_LEVEL=4

    cd "$SRC_DIR/python"
    "${PYTHON}" -m pip install . -vvv

    SP="$PREFIX/lib/python${PY_VER}/site-packages"
    cp "$SP/pyarrow/libarrow_python.so" "$PREFIX/lib/libarrow_python.so"

    rm -rf "$SP/pyarrow/tests"
    rm -rf "$SP/pyarrow/__pycache__/"
    for disabled_file in _cuda.pxd _cuda.pyx _flight.pyx _gcsfs.pyx _hdfs.pyx; do
        rm -f "$SP/pyarrow/$disabled_file"
    done

    echo "✅ PyArrow build and installation complete ✅"
}

build_r_arrow() {
    echo "============================================================"
    echo "📊 Starting R Arrow build 📊"
    echo "============================================================"

    export ARROW_HOME=${PREFIX}

    cd $SRC_DIR/r
    $R CMD INSTALL $R_ARGS .

    echo "✅ R Arrow build and installation complete ✅"
}

build_arrow_cpp

build_pyarrow

build_r_arrow

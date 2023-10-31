
mkdir build
cd build

# Configure step
cmake ${CMAKE_ARGS} \
    -DCMAKE_PREFIX_PATH:PATH=${PREFIX} \
    -DCMAKE_INSTALL_PREFIX:PATH=${PREFIX} \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_BUILD_TYPE=Release \
    -DARROW_SIMD_LEVEL=NONE \
    -DARROW_RUNTIME_SIMD_LEVEL=NONE \
    -DARROW_BUILD_TESTS=OFF \
    -DARROW_ENABLE_TIMING_TESTS=OFF \
    -DARROW_BUILD_SHARED=OFF \
    -DARROW_COMPUTE=ON \
    -DARROW_CSV=ON \
    -DARROW_JSON=ON \
    -DARROW_FILESYSTEM=ON \
    -DARROW_DATASET=ON \
    -DARROW_WITH_UTF8PROC=ON \
    -DARROW_WITH_RE2=ON \
    -Dutf8proc_LIB=${PREFIX}/lib/libutf8proc.a \
    -Dutf8proc_INCLUDE_DIR=${PREFIX}/include \
    -DRapidJSON_DIR=${PREFIX}/lib/cmake/RapidJSON/ \
    -S ../cpp -B ./


# Build step
emmake make install -j8
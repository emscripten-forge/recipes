set -e
set -x

# The native lfortran build dependency provides the runtime modules generated
# by wasm-build0.sh. Install them into the WASM host prefix for preloading.
mkdir -p "$PREFIX/lib"
cp -v "$BUILD_PREFIX"/share/lfortran/lib/*.mod "$PREFIX/lib/"

# Create build directory
mkdir -p build

emcmake cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DLFORTRAN_BUILD_ALL=no \
    -DWITH_LLVM=yes \
    -DXEUS_LFORTRAN_WASM_BUILD=yes \
    -DWITH_XEUS=no \
    -DWITH_ZSTD=no \
    -DWITH_RUNTIME_LIBRARY=no \
    -DWITH_STACKTRACE=no \
    -DWITH_WHEREAMI=no \
    -DWITH_ZLIB=no \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DCMAKE_FIND_ROOT_PATH="$PREFIX" \
    -DCMAKE_PREFIX_PATH="$PREFIX" \
    -DLLVM_DIR="$PREFIX/lib/cmake/llvm" \
    -DLLD_DIR="$PREFIX/lib/cmake/lld"

# Build and Install step
emmake make -C build -j8 install

cp build/src/lfortran/tests/test_lfortran.js "$PREFIX/bin/test_lfortran.js"
cp build/src/lfortran/tests/test_lfortran.wasm "$PREFIX/bin/test_lfortran.wasm"

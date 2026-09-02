#!/bin/bash
set -e  # Exit on error


# Specific variables for cross-compilation
if [[ "$target_platform" == "emscripten-wasm32" ]]; then
    EXTRA_FLAGS=""
elif [[ "$target_platform" == "emscripten-wasm64" ]]; then
   EXTRA_FLAGS="-m64"
else
    echo "Unsupported target_platform: $target_platform"
    exit 1
fi



# Don't use SIDE_MODULE flags for tests - they need to be standalone executables
export CFLAGS="${CFLAGS}"
export CXXFLAGS="${CXXFLAGS}"
export LDFLAGS="${LDFLAGS}"

# Build the tests
emcmake cmake -S tests -B build_tests \
  "-DCMAKE_PREFIX_PATH=${PREFIX}" \
  "-DOpenSSL_DIR=${PREFIX}/lib/cmake/OpenSSL" \
  -DCMAKE_BUILD_TYPE=Release \
  

emmake make -C build_tests

if [ -f "$PREFIX/lib/libssl.so" ]; then
    cp "$PREFIX/lib/libssl.so"    build_tests/
    cp "$PREFIX/lib/libcrypto.so" build_tests/
fi

# Run the test with Node.js
echo "Running OpenSSL tests..."
node build_tests/test_openssl


#!/bin/bash

set -eux

# Create build directory
mkdir -p build
cd build

# Set up the environment variables for cross-compiling to WASM
export SYSROOT_PATH=$EMSCRIPTEN_FORGE_EMSDK_DIR/upstream/emscripten/cache/sysroot

# Configure step with Emscripten's emcmake
emcmake cmake \
    -DCMAKE_BUILD_TYPE=Release                        \
    -DCMAKE_INSTALL_PREFIX=$PREFIX                    \
    -DXEUS_CPP_EMSCRIPTEN_WASM_BUILD=ON               \
    -DCMAKE_FIND_ROOT_PATH=$PREFIX                    \
    -DSYSROOT_PATH=$SYSROOT_PATH                      \
    -DXEUS_CPP_BUILD_TESTS=ON                         \
    ..

# Build step
emmake make -j8

# Run tests
echo "Node version:"
node --version
cd test
node test_xeus_cpp.js

# Install if tests passed
cd ..
emmake make install
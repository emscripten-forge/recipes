#!/bin/bash

# Create build directory
mkdir -p build
cd build

# Set up the environment variables for cross-compiling to WASM
export CMAKE_PREFIX_PATH=$PREFIX
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX

# Check if the target platform is WebAssembly
if [[ $target_platform == "emscripten-wasm32" ]]; then
    export USE_WASM=ON
else
    export USE_WASM=OFF
fi

# Configure step with Emscripten's emcmake
emcmake cmake ${CMAKE_ARGS} -S .. -B .                     \
    -DCMAKE_BUILD_TYPE=Release                             \
    -DCMAKE_PREFIX_PATH=$PREFIX                            \
    -DCMAKE_INSTALL_PREFIX=$PREFIX                         \
    -DXEUS_R_EMSCRIPTEN_WASM_BUILD=$USE_WASM               \
    -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ON

# Build step with emmake
emmake make -j1

# Install step
emmake make install

# Copy all files with ".wasm" extension to $PREFIX/bin
cp $SRC_DIR/build/bin/*.wasm $PREFIX/bin
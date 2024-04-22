#!/bin/bash

echo "Activating Rust"

export RUSTUP_HOME=$BUILD_PREFIX/.rustup
export CARGO_HOME=$BUILD_PREFIX/.cargo
export PATH=$CARGO_HOME/bin:$PATH


curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
rustup toolchain add 1.77.2
rustup target add wasm32-unknown-emscripten --toolchain 1.77.2 




export OPENSSL_INCLUDE_PATH=$PREFIX/include
export OPENSSL_LIBRARY_PATH=$PREFIX/lib
export OPENSSL_DIR=$PREFIX/lib
export WASM32_UNKNOWN_EMSCRIPTEN_OPENSSL_LIB_DIR=$PREFIX/lib
export WASM32_UNKNOWN_EMSCRIPTEN_OPENSSL_DIR=$PREFIX/lib
export WASM32_UNKNOWN_EMSCRIPTEN_OPENSSL_INCLUDE_DIR=$PREFIX/include


export PYO3_CROSS=1
export PYO3_PYTHON=python3
export PYO3_CROSS_PYTHON_VERSION=$PY_VER
export PYO3_CROSS_LIB_DIR=$PREFIX/lib
export PYO3_CROSS_INCLUDE_DIR=$PREFIX/include
export PYO3_PYTHON=python

export CARGO_BUILD_TARGET="wasm32-unknown-emscripten"
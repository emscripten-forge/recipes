#!/bin/bash

echo "Activating Rust"



export RUSTUP_HOME=$HOME/.rustup_emscripten_forge
export CARGO_HOME=$HOME/.cargo_emscripten_forge
export PATH=$CARGO_HOME/bin:$PATH

# if $CARO_HOME does not exist, install rustup
if [ ! -d "$CARGO_HOME" ]; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y #--default-toolchain=1.89.0
    rustup install nightly-2025-08-07
    rustup default nightly-2025-08-07
    rustup target add wasm32-unknown-emscripten
fi


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
export LDFLAGS="$LDFLAGS -L${PREFIX}/lib"

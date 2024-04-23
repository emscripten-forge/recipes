#!/bin/bash

echo "Activating Rust"

# export RUSTUP_HOME=$BUILD_PREFIX/.rustup
# export CARGO_HOME=$BUILD_PREFIX/.cargo
# export PATH=$CARGO_HOME/bin:$PATH


#echo $PKG_VERSION > ${PREFIX}/.rust_version

# load the rust version from the .rust_version file

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y #--default-toolchain=1.78.0
rustup install nightly-2024-04-222
rustup default nightly
rustup target add wasm32-unknown-emscripten




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
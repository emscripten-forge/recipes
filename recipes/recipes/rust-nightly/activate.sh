#!/bin/bash

echo "[rust-nightly] Activating..."

[ -z "${BUILD_PREFIX}" ] && export BUILD_PREFIX="${PREFIX}"

export RUSTUP_HOME=$BUILD_PREFIX/.rustup_emscripten_forge
export CARGO_HOME=$BUILD_PREFIX/.cargo_emscripten_forge
export PATH=$CARGO_HOME/bin:$PATH

export OPENSSL_INCLUDE_PATH=$PREFIX/include
export OPENSSL_LIBRARY_PATH=$PREFIX/lib
export OPENSSL_DIR=$PREFIX/lib
export WASM32_UNKNOWN_EMSCRIPTEN_OPENSSL_LIB_DIR=$PREFIX/lib
export WASM32_UNKNOWN_EMSCRIPTEN_OPENSSL_DIR=$PREFIX/lib
export WASM32_UNKNOWN_EMSCRIPTEN_OPENSSL_INCLUDE_DIR=$PREFIX/include

export PYO3_CROSS=1
export PYO3_PYTHON=python
export PYO3_CROSS_PYTHON_VERSION=$PY_VER
export PYO3_CROSS_LIB_DIR=$PREFIX/lib
export PYO3_CROSS_INCLUDE_DIR=$PREFIX/include

# To enable wasm-exceptions set RUSTFLAGS=$RUST_WASM_EXCEPTIONS
# Not all packages require this and sometimes it causes problems
export RUST_WASM_EXCEPTIONS="-Z emscripten-wasm-eh -C panic=abort"

export CARGO_BUILD_TARGET="wasm32-unknown-emscripten"
export LDFLAGS="$LDFLAGS -L${PREFIX}/lib"

source $CARGO_HOME/env
rustup default nightly

echo "[rust-nightly] Activation complete."
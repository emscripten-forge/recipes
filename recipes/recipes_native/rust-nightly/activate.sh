#!/bin/bash

echo "[rust-nightly] Activating..."

case "${target_platform:-emscripten-wasm32}" in
  emscripten-wasm64)
    export CARGO_BUILD_TARGET=wasm64-unknown-emscripten
    ;;
  *)
    export CARGO_BUILD_TARGET=wasm32-unknown-emscripten
    ;;
esac

export OPENSSL_DIR=$PREFIX/lib
export WASM32_UNKNOWN_EMSCRIPTEN_OPENSSL_LIB_DIR=$PREFIX/lib
export WASM32_UNKNOWN_EMSCRIPTEN_OPENSSL_DIR=$PREFIX/lib
export WASM32_UNKNOWN_EMSCRIPTEN_OPENSSL_INCLUDE_DIR=$PREFIX/include
export WASM64_UNKNOWN_EMSCRIPTEN_OPENSSL_LIB_DIR=$PREFIX/lib
export WASM64_UNKNOWN_EMSCRIPTEN_OPENSSL_DIR=$PREFIX/lib
export WASM64_UNKNOWN_EMSCRIPTEN_OPENSSL_INCLUDE_DIR=$PREFIX/include

export PYO3_CROSS=1
export PYO3_PYTHON=python
export PYO3_CROSS_PYTHON_VERSION=$PY_VER
export PYO3_CROSS_LIB_DIR=$PREFIX/lib
export PYO3_CROSS_INCLUDE_DIR=$PREFIX/include

# To enable wasm-exceptions set RUSTFLAGS=$RUST_WASM_EXCEPTIONS
# Not all packages require this and sometimes it causes problems
export RUST_WASM_EXCEPTIONS="-Z emscripten-wasm-eh -C panic=abort"

export LDFLAGS="$LDFLAGS -L${PREFIX}/lib"

echo "[rust-nightly] Activation complete (target: $CARGO_BUILD_TARGET)."

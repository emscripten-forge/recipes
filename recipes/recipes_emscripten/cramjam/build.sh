#!/bin/bash

set -eux

# # emcc: error: DISABLE_EXCEPTION_CATCHING=0 is not compatible with -fwasm-exceptions
# unset EMCC_CFLAGS

# # rustup toolchain install nightly
# # rustup target add wasm32-unknown-emscripten --toolchain nightly
# # rustup override set nightly
# # rustup default nightly

# # export CARGO_BUILD_TARGET=wasm32-unknown-emscripten
# # export PYTHON_SYS_EXECUTABLE=$BUILD_PREFIX/bin/python3.13
# # export RUSTUP_TOOLCHAIN=nightly
# # export PYO3_CROSS_LIB_DIR=$BUILD_PREFIX/lib
# # export PYO3_CROSS_INCLUDE_DIR=$BUILD_PREFIX/include
# # export CARGO_FEATURE_NO_DEFAULT_FEATURES=1
# # export CARGO_NO_DEFAULT_FEATURES=1
# # export MATURIN_NO_DEFAULT_FEATURES=1

# # python -m pip install . --config-settings="maturin-args=--no-default-features" --no-build-isolation --prefix $PREFIX -vvv
# # # Use maturin with all cross-compilation variables
# RUSTUP_TOOLCHAIN=nightly maturin build --release --target wasm32-unknown-emscripten -i python3.13 --no-default-features --out dist
# python -m pip install dist/*.whl --prefix $PREFIX -vvv
export RUSTFLAGS="-Z emscripten-wasm-eh"
$PYTHON -m pip install . $PIP_ARGS
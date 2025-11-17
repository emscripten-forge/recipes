#!/bin/bash


# Flags etc copied from recipes/recipes/rust/activate.sh now that we are taking rust
# itself from conda-forge.

export CARGO_HOME=$HOME/.cargo_emscripten_forge
export PATH=$CARGO_HOME/bin:$PATH

# if $CARGO_HOME does not exist, install rustup
# Need nightly rustup to support the -Z flag
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
#export LDFLAGS="$LDFLAGS -L${PREFIX}/lib"

#export RUSTFLAGS="-C link-arg=-sSIDE_MODULE=2 -Z link-native-libraries=yes -Z emscripten-wasm-eh"
#export RUSTFLAGS="-C link-arg=-sSIDE_MODULE=2 -Z link-native-libraries=no -Z emscripten-wasm-eh"
export RUSTFLAGS="-C link-arg=-sSIDE_MODULE=2 -Z emscripten-wasm-eh --verbose"



${PYTHON} -m pip  install . -vvv ${PIP_ARGS}


# Error at link time is:
# note: emcc: error: invalid export name: _ZN4core3fmt3num3imp52_$LT$impl$u20$core..fmt..Display$u20$for$u20$u32$GT$3fmt17h8a07ecdda484806aE

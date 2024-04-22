#!/bin/bash
export LDFLAGS="$LDFLAGS -L${PREFIX}/lib"


#export CARGO_HOME=$BUILD_PREFIX/.cargo
# export RUSTUP_HOME=$BUILD_PREFIX/.rustup

#export PATH=$CARGO_HOME/bin:$PATH

# curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
# rustup toolchain add stable
# rustup target add wasm32-unknown-emscripten --toolchain stable 



# # # add rust to path
# export PATH="$CARGO_HOME/bin:$PATH"




# export OPENSSL_INCLUDE_PATH=$PREFIX/include
# export OPENSSL_LIBRARY_PATH=$PREFIX/lib
# export OPENSSL_DIR=$PREFIX/lib
# export WASM32_UNKNOWN_EMSCRIPTEN_OPENSSL_LIB_DIR=$PREFIX/lib
# export WASM32_UNKNOWN_EMSCRIPTEN_OPENSSL_DIR=$PREFIX/lib
# export WASM32_UNKNOWN_EMSCRIPTEN_OPENSSL_INCLUDE_DIR=$PREFIX/include
# export CFLAGS="$CFLAGS -I$OPENSSL_INCLUDE_PATH -Wno-implicit-function-declaration"
# export LDFLAGS="$LDFLAGS -L$OPENSSL_LIBRARY_PATH -Wl,--no-entry"

# export PYO3_CROSS=1
# export PYO3_PYTHON=python3
# export PYO3_CROSS_PYTHON_VERSION=3.11
# export PYO3_CROSS_LIB_DIR=$PREFIX/lib
# export PYO3_CROSS_INCLUDE_DIR=$PREFIX/include
# export PYO3_PYTHON=python

# export CARGO_BUILD_TARGET="wasm32-unknown-emscripten"
# export RUST_BACKTRACE=1
# export CARGO_PROFILE_RELEASE_BUILD_OVERRIDE_DEBUG=true    

${PYTHON} -m pip  install . -vvv


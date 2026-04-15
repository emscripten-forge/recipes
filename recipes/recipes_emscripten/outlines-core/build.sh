#!/bin/bash
rm ./rust-toolchain
rustup target add wasm32-unknown-emscripten

cargo-bundle-licenses --format yaml --output THIRDPARTY.yml
export MATURIN_PYTHON_SYSCONFIGDATA_DIR=${PREFIX}/etc/conda/_sysconfigdata__emscripten_wasm32-emscripten.py
export OPENSSL_DIR=$PREFIX
${PYTHON} -m pip  install . -vvv


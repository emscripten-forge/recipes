#!/bin/bash
cargo-bundle-licenses --format yaml --output THIRDPARTY.yml

# export CFLAGS_wasm32-unknown-emscripten="-fwasm-exceptions"

# export RUSTFLAGS="-Z emscripten-wasm-eh -Cpanic=abort. -fwasm-exceptions"
${PYTHON} -m pip  install . -vvv


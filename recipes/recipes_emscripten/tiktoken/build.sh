#!/bin/bash
cargo-bundle-licenses --format yaml --output THIRDPARTY.yml

export MATURIN_PYTHON_SYSCONFIGDATA_DIR=${PREFIX}/etc/conda/_sysconfigdata__emscripten_wasm32-emscripten.py

export CFLAGS="$CFLAGS -fexceptions"
export CXXFLAGS="$CXXFLAGS -fexceptions"
export LDFLAGS="$LDFLAGS -fexceptions"

export EMCC_CFLAGS="-fexceptions"

${PYTHON} -m pip  install . -vvv


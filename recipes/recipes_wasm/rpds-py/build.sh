#!/bin/bash

set -eux

export MATURIN_PYTHON_SYSCONFIGDATA_DIR=${PREFIX}/etc/conda/_sysconfigdata__emscripten_${ARCH}-emscripten.py
export PYO3_USE_ABI3_FORWARD_COMPATIBILITY=1
rustup default stable
rustup component add rust-src
${PYTHON} -m pip install . -vvv
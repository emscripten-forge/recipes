#!/bin/bash


export MATURIN_PYTHON_SYSCONFIGDATA_DIR=${PREFIX}/etc/conda/_sysconfigdata__emscripten_${target_platform#emscripten-}-emscripten.py
export RUSTFLAGS="-Z link-native-libraries=yes"
${PYTHON} -m pip  install . -vvv


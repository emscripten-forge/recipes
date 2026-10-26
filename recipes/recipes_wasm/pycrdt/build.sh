#!/bin/bash


export MATURIN_PYTHON_SYSCONFIGDATA_DIR=${PREFIX}/etc/conda/_sysconfigdata__emscripten_${target_platform#emscripten-}-emscripten.py
export PYO3_USE_ABI3_FORWARD_COMPATIBILITY=1
${PYTHON} -m pip  install . -vvv


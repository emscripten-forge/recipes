#!/bin/bash


# add --no-entry to compiler flags
export CFLAGS="$CFLAGS --no-entry"
export LDFLAGS="$LDFLAGS --no-entry"

export MATURIN_PYTHON_SYSCONFIGDATA_DIR=${PREFIX}/etc/conda/_sysconfigdata__emscripten_wasm32-emscripten.py
${PYTHON} -m pip  install . -vvv

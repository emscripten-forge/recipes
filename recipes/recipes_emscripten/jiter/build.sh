#!/bin/bash

export MATURIN_PYTHON_SYSCONFIGDATA_DIR=${PREFIX}/etc/conda/_sysconfigdata__emscripten_wasm32-emscripten.py
${PYTHON} -m pip install . -vvv ${PIP_ARGS}

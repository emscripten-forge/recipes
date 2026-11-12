#!/bin/bash
set -euxo pipefail

export MATURIN_PYTHON_SYSCONFIGDATA_DIR=${PREFIX}/etc/conda/_sysconfigdata__emscripten_${target_platform#emscripten-}-emscripten.py
${PYTHON} -m pip install . -vv ${PIP_ARGS}

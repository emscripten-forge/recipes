#!/bin/bash
set -euxo pipefail
export GLPK_HEADER_PATH="$PREFIX/include"
${PYTHON} -m pip install . ${PIP_ARGS}

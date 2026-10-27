#!/bin/bash
set -e
export PYO3_CROSS_LIB_DIR=${PREFIX}/etc/conda
export PYO3_USE_ABI3_FORWARD_COMPATIBILITY=1
${PYTHON} -m pip install . -vvv

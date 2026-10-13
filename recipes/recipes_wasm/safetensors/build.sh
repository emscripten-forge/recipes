#!/bin/bash
set -e

# maturin >= 1.10 dropped MATURIN_PYTHON_SYSCONFIGDATA_DIR and reads sysconfig data
# from $PYO3_CROSS_LIB_DIR (which rust-nightly sets to $PREFIX/lib). The 6x python
# package ships a PEP 739 build-details.json there that is missing the required
# `abi.extension_suffix` field, which makes maturin bail. $PREFIX/etc/conda holds the
# cross-python _sysconfigdata file maturin can parse instead.
export PYO3_CROSS_LIB_DIR=${PREFIX}/etc/conda
export PYO3_USE_ABI3_FORWARD_COMPATIBILITY=1
${PYTHON} -m pip install . -vvv

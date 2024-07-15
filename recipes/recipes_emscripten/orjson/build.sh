#!/bin/bash
# export RUSTFLAGS="-Z link-native-libraries=yes"

export MATURIN_PYTHON_SYSCONFIGDATA_DIR=${PREFIX}/etc/conda/_sysconfigdata__emscripten_wasm32-emscripten.py


#  copy python interpreter from $BUILD_PREFIX to $PREFIX
mkdir -p $PREFIX/bin
cp $BUILD_PREFIX/bin/python $PREFIX/bin/python
${PYTHON} -m pip  install . -vvv

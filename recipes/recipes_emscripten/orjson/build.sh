#!/bin/bash
# export RUSTFLAGS="-Z link-native-libraries=yes"

export MATURIN_PYTHON_SYSCONFIGDATA_DIR=${PREFIX}/etc/conda/_sysconfigdata__emscripten_wasm32-emscripten.py


# create PYO3_CONFIG_FILE file on the fly
touch pyo3_config.toml

# Add the content to the file with the expanded BUILD_PREFIX
cat <<EOL > pyo3_config.toml
[tool.pyo3]
# Path to the Python interpreter to be used
python = "${BUILD_PREFIX}/bin/python"
EOL





#  copy python interpreter from $BUILD_PREFIX to $PREFIX
export PYO3_CROSS_PYTHON_VERSION=3.12
export PYO3_PYTHON=$BUILD_PREFIX/bin/python
export PYTHON_SYS_EXECUTABLE=$BUILD_PREFIX/bin/python
export PYO3_CROSS_LIB_DIR=$PREFIX/lib
export PYO3_CONFIG_FILE=$(pwd)/pyo3_config.toml
${PYTHON} -m pip  install . -vvv

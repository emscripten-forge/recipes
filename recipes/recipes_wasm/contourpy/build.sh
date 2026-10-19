export PYBIND11_INCLUDE_DIR=$PREFIX/include
${PYTHON} -m pip install . -vvv --no-deps --no-build-isolation \
    -Csetup-args="--cross-file=$MESON_CROSS_PYTHON_FILE"

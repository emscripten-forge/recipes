# Meson finds numpy_config via pkg_config and numpy.pc
export PKG_CONFIG_PATH="${PKGCONFIG_DIR}:$PREFIX/lib/python$PY_VER/site-packages/numpy/_core/lib/pkgconfig"

${PYTHON} -m pip install . -vvv --no-deps --no-build-isolation \
    -Csetup-args="--cross-file=$MESON_CROSS_PYTHON_FILE"

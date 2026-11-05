cp $RECIPE_DIR/emscripten.meson.cross $SRC_DIR

# write out the cross file
sed "s|@(PYTHON)|${PYTHON}|g" $SRC_DIR/emscripten.meson.cross > $SRC_DIR/emscripten.meson.new
mv $SRC_DIR/emscripten.meson.new $SRC_DIR/emscripten.meson.cross

cat $SRC_DIR/emscripten.meson.cross

# Meson finds numpy_config via pkg_config and numpy.pc
export PKG_CONFIG_PATH="${PKGCONFIG_DIR}:$PREFIX/lib/python$PY_VER/site-packages/numpy/_core/lib/pkgconfig"

${PYTHON} -m pip install . -vvv --no-deps --no-build-isolation \
    -Csetup-args="--cross-file=$SRC_DIR/emscripten.meson.cross"

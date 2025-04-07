cp $RECIPE_DIR/emscripten.meson.cross $SRC_DIR

# write out the cross file
sed "s|@(PYTHON)|${PYTHON}|g" $SRC_DIR/emscripten.meson.cross > $SRC_DIR/emscripten.meson.new
mv $SRC_DIR/emscripten.meson.new $SRC_DIR/emscripten.meson.cross

cat $SRC_DIR/emscripten.meson.cross

export PYBIND11_INCLUDE_DIR=$PREFIX/include
${PYTHON} -m pip install . -vvv --no-deps --no-build-isolation \
    -Csetup-args="--cross-file=$SRC_DIR/emscripten.meson.cross"

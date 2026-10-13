# Add correct python to the meson cross file.
cp $MESON_CROSS_FILE $SRC_DIR/emscripten.meson.cross
sed "s|@(PYTHON)|${PYTHON}|g" $SRC_DIR/emscripten.meson.cross > $SRC_DIR/emscripten.meson.new
mv $SRC_DIR/emscripten.meson.new $SRC_DIR/emscripten.meson.cross

# Remove whitespace after '-s' in LDFLAGS
export LDFLAGS="$(echo "${LDFLAGS}" | sed -E 's/-s +/-s/g')"

# Use local flang-new-wrapper that does some arg mangling.
cp $RECIPE_DIR/flang-new-wrapper $BUILD_PREFIX/bin/flang-new-wrapper

export FC=$BUILD_PREFIX/bin/flang-new-wrapper

# Meson finds numpy_config via pkg_config and numpy.pc
export PKG_CONFIG_PATH=$PREFIX/lib/python$PY_VER/site-packages/numpy/_core/lib/pkgconfig

# Install runtime plus tests (Meson install_tag=tests). Tests are packaged
# as scipy-tests, not scipy; scipy.test() needs both packages.
${PYTHON} -m pip install . ${PIP_ARGS} --no-build-isolation \
    -Csetup-args="--cross-file=$SRC_DIR/emscripten.meson.cross" \
    -Csetup-args="-Dfortran_std=none" \
    -Csetup-args="-Duse-pythran=false" \
    -Cbuild-dir="_build" \
    -Ccompile-args="--verbose" \
    -Cinstall-args="--tags=runtime,python-runtime,tests"

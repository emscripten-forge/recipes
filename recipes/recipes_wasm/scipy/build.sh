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
    -Csetup-args="--cross-file=$MESON_CROSS_PYTHON_FILE" \
    -Csetup-args="-Dfortran_std=none" \
    -Csetup-args="-Duse-pythran=false" \
    -Cbuild-dir="_build" \
    -Ccompile-args="--verbose" \
    -Cinstall-args="--tags=runtime,python-runtime,devel,tests"

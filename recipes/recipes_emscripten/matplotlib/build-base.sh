# Set up the cross file
sed "s|@(PYTHON)|${PYTHON}|g" $RECIPE_DIR/emscripten.meson.cross > $SRC_DIR/emscripten.meson.cross
cat $SRC_DIR/emscripten.meson.cross

${PYTHON} -m pip install . -vvv --no-deps --no-build-isolation \
    -Csetup-args="--cross-file=$SRC_DIR/emscripten.meson.cross" \
    -Csetup-args="-Dsystem-freetype=true" \
    -Csetup-args="-Dsystem-libraqm=true" \
    -Csetup-args="-Dsystem-qhull=true" \
    -Csetup-args="-Dmacosx=false" \
    -Ccompile-args="-v" \
    -Cbuilddir=builddir

export MATPLOTLIB_LOCATION=$PREFIX/lib/python$PY_VER/site-packages/matplotlib

# Pre-built font cache
cp $RECIPE_DIR/src/fontlist.json $MATPLOTLIB_LOCATION/
cp $RECIPE_DIR/src/Humor-Sans-1.0.ttf $MATPLOTLIB_LOCATION/mpl-data/fonts/ttf/Humor-Sans.ttf

# Save space by removing unneeded code
rm -rf $MATPLOTLIB_LOCATION/backends/qt_editor
rm -rf $MATPLOTLIB_LOCATION/backends/web_backend
rm -rf $MATPLOTLIB_LOCATION/sphinxext

#!/bin/bash

# Set up the cross file
# Note: the include folder is moved to `$BUILD_PREFIX` by the cross-python activation script
export NUMPY_INCLUDE_DIR="$BUILD_PREFIX/lib/python${PY_VER}/site-packages/numpy/core/include"
# write out the cross file
sed "s|@(NUMPY_INCLUDE_DIR)|${NUMPY_INCLUDE_DIR}|g" $RECIPE_DIR/emscripten.meson.cross > $SRC_DIR/emscripten.meson.cross.temp
sed "s|@(PYTHON)|${PYTHON}|g" $SRC_DIR/emscripten.meson.cross.temp > $SRC_DIR/emscripten.meson.cross
rm $SRC_DIR/emscripten.meson.cross.temp

cat $SRC_DIR/emscripten.meson.cross

export CFLAGS="$CFLAGS -sWASM_BIGINT"
export CXXFLAGS="$CXXFLAGS -sWASM_BIGINT"
export LDFLAGS="$LDFLAGS -sWASM_BIGINT"

${PYTHON} -m pip install . -vvv --no-deps --no-build-isolation \
    -Csetup-args="--cross-file=$SRC_DIR/emscripten.meson.cross" \
    -Csetup-args="-Dsystem-freetype=true" \
    -Csetup-args="-Dsystem-qhull=true" \
    -Csetup-args="-Dmacosx=false"

export MATPLOTLIB_LOCATION=$PREFIX/lib/python$PY_VER/site-packages/matplotlib

# Pre-built font cache
cp $RECIPE_DIR/src/fontlist.json $MATPLOTLIB_LOCATION/
cp $RECIPE_DIR/src/Humor-Sans-1.0.ttf $MATPLOTLIB_LOCATION/mpl-data/fonts/ttf/Humor-Sans.ttf

# Save space by removing unneeded code
rm -rf $MATPLOTLIB_LOCATION/backends/qt_editor
rm -rf $MATPLOTLIB_LOCATION/backends/web_backend
rm -rf $MATPLOTLIB_LOCATION/sphinxext


# # rename import _qhull to import _qhull_matplotlib in file F
# F=$MATPLOTLIB_LOCATION/tri/triangulation.py
# sed -i 's/_qhull/_qhull_matplotlib/g' $F

# # rename file $MATPLOTLIB_LOCATION/_qhull.* to $MATPLOTLIB_LOCATION/_qhull_matplotlib.*
# mv $MATPLOTLIB_LOCATION/_qhull.cpython-311-wasm32-emscripten.so $MATPLOTLIB_LOCATION/_qhull_matplotlib.cpython-311-wasm32-emscripten.so


#!/bin/bash

${PYTHON} $EMSCRIPTEN_FORGE_EMSDK_DIR/upstream/emscripten/embuilder.py build freetype --pic

export LDFLAGS="$LDFLAGS -s USE_FREETYPE=1 -s USE_LIBPNG=1 -s USE_ZLIB=1"
export CFLAGS="$CFLAGS -s USE_FREETYPE=1 -s USE_LIBPNG=1 -s USE_ZLIB=1"

$PYTHON -m pip install . --no-deps

export MATPLOTLIB_LOCATION=$PREFIX/lib/python$PY_VER/site-packages/matplotlib

# Pre-built font cache
cp $RECIPE_DIR/src/fontlist.json $MATPLOTLIB_LOCATION/
cp $RECIPE_DIR/src/Humor-Sans-1.0.ttf $MATPLOTLIB_LOCATION/mpl-data/fonts/ttf/Humor-Sans.ttf

# Save space by removing unneeded code
rm -rf $MATPLOTLIB_LOCATION/backends/qt_editor
rm -rf $MATPLOTLIB_LOCATION/backends/web_backend
rm -rf $MATPLOTLIB_LOCATION/sphinxext

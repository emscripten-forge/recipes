echo "EMSCRIPTEN_FORGE_EMSDK_DIR $EMSCRIPTEN_FORGE_EMSDK_DIR: " $EMSCRIPTEN_FORGE_EMSDK_DIR

# pushd $CONDA_EMSDK_DIR
${PYTHON} $EMSCRIPTEN_FORGE_EMSDK_DIR/upstream/emscripten/embuilder.py build freetype --pic
${PYTHON} $EMSCRIPTEN_FORGE_EMSDK_DIR/upstream/emscripten/embuilder.py build libjpeg --pic
# popd

export LDFLAGS="${LDFLAGS} -s USE_LIBJPEG"
export CFLAGS="${CFLAGS} -s USE_ZLIB=1 -s USE_LIBJPEG=1 -s USE_FREETYPE=1 -s SIDE_MODULE=1"
${PYTHON} -m pip  install .

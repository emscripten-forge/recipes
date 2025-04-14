echo "EMSCRIPTEN_FORGE_EMSDK_DIR $EMSCRIPTEN_FORGE_EMSDK_DIR: " $EMSCRIPTEN_FORGE_EMSDK_DIR

# pushd $CONDA_EMSDK_DIR
$EMSCRIPTEN_FORGE_EMSDK_DIR/upstream/emscripten/embuilder build freetype --pic
$EMSCRIPTEN_FORGE_EMSDK_DIR/upstream/emscripten/embuilder build libjpeg --pic
# popd

export LDFLAGS="${LDFLAGS} -s USE_LIBJPEG"
export CFLAGS="${CFLAGS} -s USE_ZLIB=1 -s USE_LIBJPEG=1 -s USE_FREETYPE=1 -s SIDE_MODULE=1"



# replace version in setup.py
sed -i.bak "s/PILLOW_PACKAGE_VERSION_PLACEHOLDER/$PKG_VERSION/g" setup.py


${PYTHON} -m pip  install .


rm -rf $PREFIX/bin

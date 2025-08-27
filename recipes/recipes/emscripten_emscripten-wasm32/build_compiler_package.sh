#!/bin/bash

mkdir -p ${PREFIX}/bin

# Copy the [de]activate scripts to $PREFIX/etc/conda/[de]activate.d.
# This will allow them to be run on environment activation.
for TASK in "activate" "deactivate"
do
    mkdir -p "${PREFIX}/etc/conda/${TASK}.d"
    envsubst '$PKG_VERSION' < "${RECIPE_DIR}/${TASK}.sh" > "${PREFIX}/etc/conda/${TASK}.d/${TASK}_${PKG_NAME}.sh"
    cp "${PREFIX}/etc/conda/${TASK}.d/${TASK}_${PKG_NAME}.sh" "${PREFIX}/bin/${TASK}_emscripten.sh"
done

export EMSDK_PYTHON=${BUILD_PREFIX}/bin/python

./emsdk install $PKG_VERSION

export EMSDK=.

echo "emsdk patching"
pushd upstream/emscripten
cat $RECIPE_DIR/patches/*.patch | patch -p1 --verbose
popd
echo "...done"


mkdir -p $PREFIX/opt/emsdk/
cp -r $EMSDK/upstream $PREFIX/opt/emsdk/upstream
rm -rf $PREFIX/opt/emsdk/upstream/emscripten/test/

for file in $PREFIX/opt/emsdk/upstream/bin/*; do
    echo "Linking $file"
    ln -sf $file $PREFIX/bin/
done

for file in $PREFIX/opt/emsdk/upstream/emscripten/*; do
  # Check if the file is executable
  if [ -x "$file" ] && [ ! -d "$file" ]; then
    # Create a symbolic link in the $PREFIX/bin directory
    echo "Linking $file"
    ln -sf $file $PREFIX/bin/
  fi

  # Check if the ends with .py
  if [[ $file == *.py ]]; then
    # Create a symbolic link in the $PREFIX/bin directory
    echo "Linking $file"
    ln -sf $file $PREFIX/bin/
  fi
done

# Add wasm-opt wrapper. See NOTE in patches/wasm-opt-wrapper.
EMSDK_DIR=$PREFIX/opt/emsdk/upstream
mv $EMSDK_DIR/bin/wasm-opt $EMSDK_DIR/bin/wasm-opt-original
cp $RECIPE_DIR/patches/wasm-opt-wrapper $EMSDK_DIR/bin/wasm-opt
chmod +x $EMSDK_DIR/bin/wasm-opt

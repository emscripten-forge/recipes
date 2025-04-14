#!/bin/bash

# Copy the [de]activate scripts to $PREFIX/etc/conda/[de]activate.d.
# This will allow them to be run on environment activation.
for CHANGE in "activate" "deactivate"
do
    mkdir -p "${PREFIX}/etc/conda/${CHANGE}.d"
    envsubst '$PKG_VERSION' < "${RECIPE_DIR}/${CHANGE}.sh" > "${PREFIX}/etc/conda/${CHANGE}.d/${PKG_NAME}_${CHANGE}.sh"
done

mkdir -p ${PREFIX}/bin
cp "${PREFIX}/etc/conda/${CHANGE}.d/${PKG_NAME}_${CHANGE}.sh" ${PREFIX}/bin/activate_emscripten.sh

export EMSDK_PYTHON=${BUILD_PREFIX}/bin/python

./emsdk install $PKG_VERSION

# export EMSDK=/Users/wolfv/Programs/emscripten-forge/emscripten_forge_emsdk_install
export EMSDK=.


echo "emsdk patching"
pushd upstream/emscripten
cat $RECIPE_DIR/patches/*.patch | patch -p1 --verbose 
popd    
echo "...done"




mkdir -p $PREFIX/opt/emsdk/
cp -r $EMSDK/upstream $PREFIX/opt/emsdk/upstream
rm -rf $PREFIX/opt/emsdk/upstream/emscripten/test/

mkdir -p $PREFIX/bin

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

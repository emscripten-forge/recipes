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
# cat $RECIPE_DIR/patches/*.patch | patch -p1 --verbose 
# run each patch individually to see which one fails
for patch_file in $RECIPE_DIR/patches/*.patch; 
do 
    echo "Applying patch: $patch_file"
    patch -p1 --verbose < "$patch_file"
    if [ $? -ne 0 ]; then
        echo "Failed to apply patch: $patch_file"
    else
        echo "Successfully applied patch: $patch_file"
    fi
done
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
done

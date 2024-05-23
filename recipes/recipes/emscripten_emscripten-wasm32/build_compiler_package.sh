# Copy the [de]activate scripts to $PREFIX/etc/conda/[de]activate.d.
# This will allow them to be run on environment activation.
for CHANGE in "activate" "deactivate"
do
    mkdir -p "${PREFIX}/etc/conda/${CHANGE}.d"
    envsubst '$PKG_VERSION' < "${RECIPE_DIR}/${CHANGE}.sh" > "${PREFIX}/etc/conda/${CHANGE}.d/${PKG_NAME}_${CHANGE}.sh"
done

mkdir -p ${PREFIX}/bin
cp "${PREFIX}/etc/conda/${CHANGE}.d/${PKG_NAME}_${CHANGE}.sh" ${PREFIX}/bin/activate_emscripten.sh



./emsdk install $PKG_VERSION
mkdir -p $PREFIX/opt/emsdk/
cp -r ./ $PREFIX/opt/emsdk/
rm -rf $PREFIX/opt/emsdk/.git/
rm -rf $PREFIX/opt/emsdk/upstream/emscripten/test/
rm -rf $PREFIX/opt/emsdk/downloads
rm -rf $PREFIX/opt/emsdk/python
# rm -rf $PREFIX/opt/emsdk/node
rm -rf $PREFIX/opt/emsdk/bazel

mkdir -p $PREFIX/bin
for file in $PREFIX/opt/emsdk/bin/*; do
    ln -s "$file" "$PREFIX/bin/"
done
# TODO can we get rid of `upstream/emscripten/system`?
# that folder contains stuff like `eigen`, ...

# - ./emsdk activate ${{ version }}
# - source ./emsdk_env.sh
# - exit 1
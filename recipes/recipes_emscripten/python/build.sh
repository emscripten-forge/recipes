#!/bin/bash

set -euxo pipefail

mkdir -p $PREFIX/include
mkdir -p $PREFIX/lib
mkdir -p $PREFIX/bin
mkdir -p $PREFIX/etc/conda

# Move all python package files to the build folder
export BUILD=build/${PKG_VERSION}/Python-${PKG_VERSION}
mkdir -p ${BUILD}
mv Makefile.pre.in README.rst aclocal.m4 config.guess config.sub setup.py pyconfig.h.in install-sh configure.ac ${BUILD}
mv Doc Grammar Include LICENSE Lib Mac Misc Modules Objects PC PCbuild Parser Programs Python Tools configure ${BUILD}

# copy the LICENSE file back for the recipe
cp ${BUILD}/LICENSE .

# create a symlink from  $BUILD_PREFIX/bin/python3.11 to $BUILD_PREFIX/bin/python.js
# since the python build script overwrites the env variable PYTHON to python.js
# as it assumes this is the correct name for the python binary when building for emscripten.
# But emscripten itself (emcc/emar/...) relies on the env variable PYTHON to be set to python3.11
ln -s $BUILD_PREFIX/bin/python3.11 $BUILD_PREFIX/bin/python.js

# create an empty emsdk_env.sh in CONDA_EMSDK_DIR
echo "" > $EMSCRIPTEN_FORGE_EMSDK_DIR/emsdk_env.sh
# make it executable
chmod +x $EMSCRIPTEN_FORGE_EMSDK_DIR/emsdk_env.sh

cp ${RECIPE_DIR}/Makefile .
cp ${RECIPE_DIR}/Makefile.envs .
cp -r ${RECIPE_DIR}/patches .
cp ${RECIPE_DIR}/Setup.local .
cp ${RECIPE_DIR}/adjust_sysconfig.py .

make 

# (TODO move in recipe) install libmpdec and libexpat
cp ${BUILD}/Modules/_decimal/libmpdec/libmpdec.a $PREFIX/lib
cp ${BUILD}/Modules/expat/libexpat.a     $PREFIX/lib

# a fake wheel command
touch $PREFIX/bin/wheel
# append #!/bin/bash

echo "#!/bin/bash" >> $PREFIX/bin/wheel
echo "echo \"wheel is not a supported on this platform.\"" >> $PREFIX/bin/wheel
chmod +x $PREFIX/bin/wheel

# a fake pip command
touch $PREFIX/bin/pip
echo "#!/bin/bash" >> $PREFIX/bin/pip
echo "echo \"pip is not a supported on this platform.\"" >> $PREFIX/bin/pip
chmod +x $PREFIX/bin/pip

# a fake python3 command
touch $PREFIX/bin/python3.11
echo "#!/bin/bash" >> $PREFIX/bin/python3.11
echo "echo \"python3 is not a supported on this platform.\"" >> $PREFIX/bin/python3.11
chmod +x $PREFIX/bin/python3.11

# create symlink st. all possible python3.11 commands are available
ln -s $PREFIX/bin/python3.11 $PREFIX/bin/python
ln -s $PREFIX/bin/python3.11 $PREFIX/bin/python3

# copy sysconfigdata
cp $PREFIX/sysconfigdata/_sysconfigdata__emscripten_wasm32-emscripten.py  $PREFIX/etc/conda/
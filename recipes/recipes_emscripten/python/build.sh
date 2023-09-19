
# make some directories
mkdir -p $PREFIX/include
mkdir -p $PREFIX/lib
mkdir -p $PREFIX/bin
mkdir -p $PREFIX/etc/conda
mkdir -p cpython/build


# this only overwrite the install path
cp $RECIPE_DIR/Makefile.envs  .

# pyodide uses cc instead of emcc so we need to overwrite this
cp $RECIPE_DIR/adjust_sysconfig.py  ./cpython/adjust_sysconfig.py


# overwrite $RECIPEDIR/pyodide_env.sh with am empty file
# since we do not want to use the pyodide_env.sh from pyodide
echo "" > $RECIPE_DIR/pyodide_env.sh


# create a symlink from  $BUILD_PREFIX/bin/python3.11 to $BUILD_PREFIX/bin/python.js
# since the python build script overwrites the env variable PYTHON to python.js
# as it assumes this is the correct name for the python binary when building for emscripten.
# But emscripten itself (emcc/emar/...) relies on the env variable PYTHON to be set to python3.11
ln -s $BUILD_PREFIX/bin/python3.11 $BUILD_PREFIX/bin/python.js

# create a symlink from $BUILD_PREFIX/emsdk directory to this dir emsdk.
# This allows us to overwrite the emsdk from pyodide
rm -rf emsdk
mkdir -p emsdk
cd emsdk
ln -s $CONDA_EMSDK_DIR emsdk
cd ..


# when only building libffi we need to uncomment the following line
# mkdir -p cpython/build/Python-3.11.3/Include

#################################################################
#  THE ACTUAL BUILD
make -C cpython 
################################################################


# install libffi (we do this in libffi_pyodide)
#cp -r cpython/build/libffi/target/ $PREFIX/

# (TODO move in recipe) install libmpdec and libexpat
cp cpython/build/Python-3.11.3/Modules/_decimal/libmpdec/libmpdec.a $PREFIX/lib
cp cpython/build/Python-3.11.3/Modules/expat/libexpat.a     $PREFIX/lib


# a fake wheel command
touch $PREFIX/bin/wheel
echo "wheel is not a supported wheel on this platform." > $PREFIX/bin/wheel
chmod +x $PREFIX/bin/wheel

# a fake pip command
touch $PREFIX/bin/pip
echo "pip is not a supported pip on this platform." > $PREFIX/bin/pip
chmod +x $PREFIX/bin/pip

# a fake python3 command
touch $PREFIX/bin/python3.11
echo "python3 is not a supported python3 on this platform." > $PREFIX/bin/python3.11
chmod +x $PREFIX/bin/python3.11

# create symlink st. all possible python3.11 commands are available
ln -s $PREFIX/bin/python3.11 $PREFIX/bin/python
ln -s $PREFIX/bin/python3.11 $PREFIX/bin/python3

# copy sysconfigdata
cp $PREFIX/sysconfigdata/_sysconfigdata__emscripten_wasm32-emscripten.py  $PREFIX/etc/conda/



# remove the emcc symlink in the $BUILD_PREFIX/bin
rm $BUILD_PREFIX/bin/emcc

# make callable
chmod +x $RECIPE_DIR/emcc_wrapper.sh

# create symlink to $RECIPE_DIR/emcc_wrapper.sh 
ln -s $RECIPE_DIR/emcc_wrapper.sh $BUILD_PREFIX/bin/emcc

export CFLAGS="${CFLAGS}  -I$BUILD_PREFIX/lib/python$PY_VER/site-packages/numpy/_core/include/"

export HDF5_DIR=${PREFIX}

# tell setup.py to not 'pip install' exact package requirements
export H5PY_SETUP_REQUIRES="0"

# tell setup_configure.py not to compile with ROS3 driver support
export H5PY_ROS3="0"
export H5PY_DIRECT_VFD='0'

# Disable MPI support
export HDF5_MPI=OFF

# Explitly set HDF5 version
export HDF5_VERSION=1.12.3

${PYTHON} -m pip install . -vvv
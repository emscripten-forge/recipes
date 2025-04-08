export HDF5_MPI=OFF
export H5PY_SETUP_REQUIRES="0"
export HDF5_VERSION=1.12.3
export HDF5_DIR=$PREFIX

export CFLAGS="${CFLAGS}  -I$BUILD_PREFIX/lib/python$PY_VER/site-packages/numpy/_core/include/"


${PYTHON} -m pip install . -vvv 
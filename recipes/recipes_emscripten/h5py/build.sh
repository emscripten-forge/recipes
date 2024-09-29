#!/bin/bash

export HDF5_DIR=${PREFIX}

# tell setup.py to not 'pip install' exact package requirements
export H5PY_SETUP_REQUIRES="0"

# tell setup_configure.py not to compile with ROS3 driver support
export H5PY_ROS3="0"
export H5PY_DIRECT_VFD='0'

# Disable MPI support
export HDF5_MPI=OFF

# Explitly set HDF5 version
export HDF5_VERSION=1.12.2

"${PYTHON}" -m pip install . --no-deps --ignore-installed --no-cache-dir -vv
#!/bin/bash

export HDF5_DIR=${PREFIX}

# tell setup.py to not 'pip install' exact package requirements
export H5PY_SETUP_REQUIRES="0"

# tell setup_configure.py not to compile with ROS3 driver support
export H5PY_ROS3="0"
export H5PY_DIRECT_VFD='0'

"${PYTHON}" -m pip install . --no-deps --ignore-installed --no-cache-dir -vv

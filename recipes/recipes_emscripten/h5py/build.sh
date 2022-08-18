#!/bin/bash
export HDF5_MPI=OFF
export H5PY_SETUP_REQUIRES="0"
export HDF5_VERSION=1.12.1


${PYTHON} -m pip  install .

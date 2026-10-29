#!/bin/bash

export PROJ_DIR=$PREFIX

# if version is not set, the python build script
# tries to call the proj binary to get the version
export PROJ_VERSION="$(PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig pkg-config --modversion proj)"
echo "PROJ_VERSION=${PROJ_VERSION}"

${PYTHON} -m pip install -vv .

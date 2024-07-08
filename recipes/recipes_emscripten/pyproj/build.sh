#!/bin/bash

# # the binary is needed ....
# cp $BUILD_PREFIX/bin/proj $PREFIX/bin/proj
export PROJ_DIR=$PREFIX

# if version is not set, the python build script
# tries to call the proj binary to get the version
export PROJ_VERSION="9.4.1"



${PYTHON} -m pip install -vv .


# rm $PREFIX/bin/proj
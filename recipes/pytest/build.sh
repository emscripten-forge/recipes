#!/bin/bash
ls $BUILD_PREFIX/venv/bin/
echo "PYTHON"


# export EMCC_DEBUG=1
export LDFLAGS="-s MODULARIZE=1  -s LINKABLE=1  -s EXPORT_ALL=1  -s WASM=1  -std=c++14  -s LZ4=1 -s SIDE_MODULE=1"
# export LDFLAGS="-s SIDE_MODULE=1"

LDFLAGS="$LDFLAGS"  python -m pip install *.whl

# echo 'version=7.1.1; version_tuple=(7,1,1)' > _version.py
# mkdir -p ${PREFIX}/lib/python3.10/side-packages/_pytest/
# cp _version.py ${PREFIX}/lib/python3.10/side-packages/_pytest 

# echo 'version=7.1.1; version_tuple=(7,1,1)' > _version
# mkdir -p ${PREFIX}/lib/python3.10/side-packages/_pytest/
# cp _version ${PREFIX}/lib/python3.10/side-packages/_pytest 

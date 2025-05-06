#!/bin/bash

echo "Setting up cross-python"
set -ex # REMOVE

# PYTHON_BUILD is the python executable from the build platform
# PYTHON_HOST is the python executable from the host platform (wasm)
# NOTE: bin/python, bin/python3, bin/python3.1, etc are symlinks to
# bin/python3.13 or the corresponding python version
unset PYTHON # this is PYTHON_HOST
PYTHON_BUILD=$BUILD_PREFIX/bin/python
PYTHON_HOST=$PREFIX/bin/python

# major.minor
PY_VER=$($PYTHON_BUILD -c "import sys; print('{}.{}'.format(*sys.version_info[:2]))")


# this will activate emscripten in case it has not yet been activated
source $CONDA_PREFIX/etc/conda/activate.d/activate_emscripten_emscripten-wasm32.sh

# NOTE: Restore if needed
# sed -i 's/if _os.name == "posix" and _sys.platform == "darwin":/if False:/g' \
#   $BUILD_PREFIX/lib/python${PY_VER}/ctypes/__init__.py

sysconfigdata_fn=${PREFIX}/etc/conda/_sysconfigdata__emscripten_wasm32-emscripten.py

$PYTHON_BUILD -m crossenv $PYTHON_HOST \
    --sysroot $PREFIX \
    --without-pip $BUILD_PREFIX/venv \
    --sysconfigdata-file "$sysconfigdata_fn" \
    --cc emcc \
    --cxx emcc

# # Undo cross-python's changes
# # See https://github.com/conda-forge/h5py-feedstock/pull/104
# rm -rf $BUILD_PREFIX/venv/lib/$(basename $sysconfigdata_fn)
# cp $sysconfigdata_fn $BUILD_PREFIX/venv/lib/$(basename $sysconfigdata_fn)

# For recipes using {{ PYTHON }}
# cross/bin/python is a shell script that sets up the environment
cp $BUILD_PREFIX/venv/cross/bin/python $PREFIX/bin/python

export PYTHON=$PYTHON_BUILD

# undo symlink
rm $BUILD_PREFIX/venv/build/bin/python
cp $BUILD_PREFIX/bin/python $BUILD_PREFIX/venv/build/bin/python

# For recipes looking at python on PATH
rm $BUILD_PREFIX/bin/python
echo "#!/bin/bash" > $BUILD_PREFIX/bin/python
echo "exec $PREFIX/bin/python \"\$@\"" >> $BUILD_PREFIX/bin/python
chmod +x $BUILD_PREFIX/bin/python


rm -r $BUILD_PREFIX/venv/cross
if [[ -d "$PREFIX/lib/python$PY_VER/site-packages/" ]]; then
  rsync -a --exclude="*.so" --exclude="*.dylib" \
    -I $PREFIX/lib/python$PY_VER/site-packages/ \
    $BUILD_PREFIX/lib/python$PY_VER/site-packages/
fi

rm -r $BUILD_PREFIX/venv/lib/python$PY_VER/site-packages
ln -s $BUILD_PREFIX/lib/python$PY_VER/site-packages \
      $BUILD_PREFIX/venv/lib/python$PY_VER/site-packages
sed -i.bak "s@$BUILD_PREFIX/venv/lib@$BUILD_PREFIX/venv/lib', '$BUILD_PREFIX/venv/lib/python$PY_VER/site-packages@g" $PYTHON_HOST

if [[ "${PYTHONPATH}" != "" ]]; then
  _CONDA_BACKUP_PYTHONPATH=${PYTHONPATH}
fi

export PYTHONPATH=$BUILD_PREFIX/venv/lib/python$PY_VER/site-packages


# setting up flags
export LDFLAGS="$EM_FORGE_SIDE_MODULE_LDFLAGS"
export CFLAGS="$EM_FORGE_SIDE_MODULE_CFLAGS"

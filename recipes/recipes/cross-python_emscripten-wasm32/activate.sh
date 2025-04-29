#!/bin/bash

set -ex

# PYTHON_BUILD is the python executable from the build platform
# PYTHON_HOST is the python executable from the host platform (wasm)
# NOTE: bin/python, bin/python3, bin/python3.1, etc are symlinks to
# bin/python3.13 or the corresponding python version
unset PYTHON # this is PYTHON_HOST
PYTHON_BUILD=$BUILD_PREFIX/bin/python
PYTHON_HOST=$PREFIX/bin/python

PY_VER_MAJOR_MINOR=$($PYTHON_BUILD -c 'import sys; print(str(sys.version_info[0])+"."+str(sys.version_info[1]))')

# create fake python3 wasm binary
mkdir -p $PREFIX/bin
cp $BUILD_PREFIX/bin/python3 $PREFIX/bin


# this will activate emscripten in case it has not yet been activated
source $CONDA_PREFIX/etc/conda/activate.d/activate_emscripten_emscripten-wasm32.sh


echo "Setting up cross-python"
PY_VER=$($BUILD_PREFIX/bin/python -c "import sys; print('{}.{}'.format(*sys.version_info[:2]))")
if [ -d "$PREFIX/lib_pypy" ]; then
  sysconfigdata_fn=$(find "$PREFIX/lib_pypy/" -name "_sysconfigdata_*.py" -type f)
elif [ -d "$PREFIX/lib/pypy$PY_VER" ]; then
  sysconfigdata_fn=$(find "$PREFIX/lib/pypy$PY_VER/" -name "_sysconfigdata_*.py" -type f)
else
  # find "$PREFIX/lib/" -name "_sysconfigdata*.py" -not -name ${_CONDA_PYTHON_SYSCONFIGDATA_NAME}.py -type f -exec rm -f {} +
  sysconfigdata_fn=${PREFIX}/etc/conda/_sysconfigdata__emscripten_wasm32-emscripten.py
  envsubst < $sysconfigdata_fn >${BUILD_PREFIX}/etc/conda/_sysconfigdata__emscripten_wasm32-emscripten_new.py
  sysconfigdata_fn=${BUILD_PREFIX}/etc/conda/_sysconfigdata__emscripten_wasm32-emscripten_new.py
fi

sed -i 's/if _os.name == "posix" and _sys.platform == "darwin":/if False:/g' $BUILD_PREFIX/lib/python${PY_VER_MAJOR_MINOR}/ctypes/__init__.py


unset _CONDA_PYTHON_SYSCONFIGDATA_NAME
$BUILD_PREFIX/bin/python3 -m crossenv $PREFIX/bin/python3 \
    --sysroot $PREFIX \
    --without-pip $BUILD_PREFIX/venv \
    --sysconfigdata-file "$sysconfigdata_fn" \
    --cc emcc \
    --cxx emcc

# Undo cross-python's changes
# See https://github.com/conda-forge/h5py-feedstock/pull/104
rm -rf $BUILD_PREFIX/venv/lib/$(basename $sysconfigdata_fn)
cp $sysconfigdata_fn $BUILD_PREFIX/venv/lib/$(basename $sysconfigdata_fn)

# For recipes using {{ PYTHON }}
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

if [[ -f "$PREFIX/bin/pypy" ]]; then
  rm -rf $BUILD_PREFIX/venv/lib/pypy$PY_VER
  mkdir -p $BUILD_PREFIX/venv/lib/python$PY_VER
  ln -s $BUILD_PREFIX/venv/lib/python$PY_VER $BUILD_PREFIX/venv/lib/pypy$PY_VER
fi

rm -rf $BUILD_PREFIX/venv/cross
if [[ -d "$PREFIX/lib/python$PY_VER/site-packages/" ]]; then
  rsync -a --exclude="*.so" --exclude="*.dylib" -I $PREFIX/lib/python$PY_VER/site-packages/ $BUILD_PREFIX/lib/python$PY_VER/site-packages/
fi
rm -rf $BUILD_PREFIX/venv/lib/python$PY_VER/site-packages
ln -s $BUILD_PREFIX/lib/python$PY_VER/site-packages $BUILD_PREFIX/venv/lib/python$PY_VER/site-packages
sed -i.bak "s@$BUILD_PREFIX/venv/lib@$BUILD_PREFIX/venv/lib', '$BUILD_PREFIX/venv/lib/python$PY_VER/site-packages@g" $PYTHON_HOST
rm -f $PYTHON.bak

if [[ "${PYTHONPATH}" != "" ]]; then
  _CONDA_BACKUP_PYTHONPATH=${PYTHONPATH}
fi

unset sysconfigdata_fn
export PYTHONPATH=$BUILD_PREFIX/venv/lib/python$PY_VER/site-packages


# setting up flags

export LDFLAGS="$EM_FORGE_SIDE_MODULE_LDFLAGS"
export CFLAGS="$EM_FORGE_SIDE_MODULE_CFLAGS"

echo "🧿🧿🧿"
printenv
echo "🧿🧿🧿"
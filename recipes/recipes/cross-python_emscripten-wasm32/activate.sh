#!/bin/bash

set -ex # REMOVE

# NOTE: bin/python, bin/python3, bin/python3.1, etc are symlinks to
# bin/python3.13 or the corresponding python version
unset PYTHON
PYTHON_BUILD=$BUILD_PREFIX/bin/python
PYTHON_HOST=$PREFIX/bin/python

# major.minor
PY_VER=$($PYTHON_BUILD -c "import sys; print('{}.{}'.format(*sys.version_info[:2]))")

# Activate emscripten in case it has not yet been activated
source $CONDA_PREFIX/etc/conda/activate.d/activate_emscripten_emscripten-wasm32.sh

SYSCONFIG_FILE=$PREFIX/etc/conda/_sysconfigdata__emscripten_wasm32-emscripten.py

# NOTE: this makes changes to prefix, build_prefix, and the virtual cross env.
# It should only be run once.
if [[ ! -d "$BUILD_PREFIX/venv" ]]; then
  echo "⭐⭐⭐ Setting up cross-python"
  $PYTHON_BUILD -m crossenv $PYTHON_HOST \
      --sysroot $PREFIX \
      --without-pip $BUILD_PREFIX/venv \
      --sysconfigdata-file $SYSCONFIG_FILE \
      --cc emcc \
      --cxx emcc

  # NOTE: cross/bin/python is a shell script that sets up the cross environment
  # This becomes the ${PYTHON} executable used in package recipes
  cp $BUILD_PREFIX/venv/cross/bin/python $PREFIX/bin/python

  # Undo symlink
  rm $BUILD_PREFIX/venv/build/bin/python
  cp $BUILD_PREFIX/bin/python $BUILD_PREFIX/venv/build/bin/python

  if [[ -d "$PREFIX/lib/python$PY_VER/site-packages/" ]]; then
    rsync -a -I --exclude="*.so" --exclude="*.dylib" \
      $PREFIX/lib/python$PY_VER/site-packages/ \
      $BUILD_PREFIX/lib/python$PY_VER/site-packages/
  fi

  rm -r $BUILD_PREFIX/venv/lib/python$PY_VER/site-packages
  ln -s $BUILD_PREFIX/lib/python$PY_VER/site-packages \
        $BUILD_PREFIX/venv/lib/python$PY_VER/site-packages
  sed -i.bak "s@$BUILD_PREFIX/venv/lib@$BUILD_PREFIX/venv/lib', '$BUILD_PREFIX/venv/lib/python$PY_VER/site-packages@g" $PYTHON_HOST

fi

if [[ "${PYTHONPATH}" != "" ]]; then
  _CONDA_BACKUP_PYTHONPATH=${PYTHONPATH}
fi
export PYTHONPATH=$BUILD_PREFIX/venv/lib/python$PY_VER/site-packages
export PYTHON=$PYTHON_HOST

# Set up flags
export LDFLAGS="$EM_FORGE_SIDE_MODULE_LDFLAGS"
export CFLAGS="$EM_FORGE_SIDE_MODULE_CFLAGS"

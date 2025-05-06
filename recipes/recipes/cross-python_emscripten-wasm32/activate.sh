#!/bin/bash

# Setting up the cross-python environment should only occur once
if [ -z ${EMSCRIPTEN_FORGE_PYTHON_ACTIVATED+x} ]; then

  echo "Setting up cross-python"
  set -ex # REMOVE

  export EMSCRIPTEN_FORGE_PYTHON_ACTIVATED=1

  # PYTHON_BUILD is the python executable from the build platform
  # PYTHON_HOST is the python executable from the host platform (wasm)
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

  $PYTHON_BUILD -m crossenv $PYTHON_HOST \
      --sysroot $PREFIX \
      --without-pip $BUILD_PREFIX/venv \
      --sysconfigdata-file $SYSCONFIG_FILE \
      --cc emcc \
      --cxx emcc

  # NOTE: cross/bin/python is a shell script that sets up the cross environment
  # For recipes using {{ PYTHON }}
  cp $BUILD_PREFIX/venv/cross/bin/python $PREFIX/bin/python
  export PYTHON=$PYTHON_HOST

  # undo symlink
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

  if [[ "${PYTHONPATH}" != "" ]]; then
    _CONDA_BACKUP_PYTHONPATH=${PYTHONPATH}
  fi

  export PYTHONPATH=$BUILD_PREFIX/venv/lib/python$PY_VER/site-packages


  # setting up flags
  export LDFLAGS="$EM_FORGE_SIDE_MODULE_LDFLAGS"
  export CFLAGS="$EM_FORGE_SIDE_MODULE_CFLAGS"

fi

#!/bin/bash

# bin/python, bin/python3, bin/python3.1, etc are symlinks to bin/python3.13
# or the corresponding python version
unset PYTHON
PYTHON_BUILD=$BUILD_PREFIX/bin/python
PYTHON_HOST=$PREFIX/bin/python

# major.minor
PY_VER=$($PYTHON_BUILD -c "import sys; print('{}.{}'.format(*sys.version_info[:2]))")

# WARNING: this makes changes to prefix, build_prefix, and the virtual cross env.
# It should only be run once.
if [[ ! -d "$BUILD_PREFIX/venv" ]]; then
  echo "Setting up cross-python environment"

  SYSCONFIG_FILE=$PREFIX/etc/conda/_sysconfigdata__emscripten_wasm32-emscripten.py

  $PYTHON_BUILD -m crossenv $PYTHON_HOST \
      --sysroot $PREFIX \
      --without-pip $BUILD_PREFIX/venv \
      --sysconfigdata-file $SYSCONFIG_FILE \
      --cc emcc \
      --cxx emcc

  # cross/bin/python is a shell script that sets up the cross environment
  # This becomes the ${PYTHON} executable used in package recipes
  cp $BUILD_PREFIX/venv/cross/bin/python $PREFIX/bin/python

  # Undo symlink to build_prefix python
  rm $BUILD_PREFIX/venv/build/bin/python
  cp $BUILD_PREFIX/bin/python $BUILD_PREFIX/venv/build/bin/python

  # Sync wasm packages from prefix into build_prefix
  if [[ -d "$PREFIX/lib/python$PY_VER/site-packages/" ]]; then
    rsync -a -I --exclude="*.so" --exclude="*.dylib" \
      $PREFIX/lib/python$PY_VER/site-packages/ \
      $BUILD_PREFIX/lib/python$PY_VER/site-packages/
  fi

  # Sync python headers from prefix into build_prefix
  if [[ -d "$PREFIX/include/python$PY_VER" ]]; then
    rsync -a -I -r $PREFIX/include/python$PY_VER $BUILD_PREFIX/include/python$PY_VER
  fi

  # Point the cross env to the freshly synced packages in build_prefix
  rm -r $BUILD_PREFIX/venv/lib/python$PY_VER/site-packages
  ln -s $BUILD_PREFIX/lib/python$PY_VER/site-packages \
        $BUILD_PREFIX/venv/lib/python$PY_VER/site-packages
  sed -i "s@$BUILD_PREFIX/venv/lib@$BUILD_PREFIX/venv/lib', '$BUILD_PREFIX/venv/lib/python$PY_VER/site-packages@g" $PYTHON_HOST

  # Copy the sysconfigdata file
  rm $BUILD_PREFIX/venv/lib/_sysconfigdata__emscripten_wasm32-emscripten.py
  cp $SYSCONFIG_FILE $BUILD_PREFIX/venv/lib
  cp $SYSCONFIG_FILE $BUILD_PREFIX/lib/python$PY_VER

fi

export _PYTHON_SYSCONFIGDATA_NAME="_sysconfigdata__emscripten_wasm32-emscripten"

if [[ "${PYTHONPATH}" != "" ]]; then
  _CONDA_BACKUP_PYTHONPATH=${PYTHONPATH}
fi
export PYTHONPATH=$BUILD_PREFIX/venv/lib/python$PY_VER/site-packages
export PYTHON=$PYTHON_HOST # This should be a script to set up the cross env
export PIP_ARGS="--prefix=$PREFIX --no-deps -vv"

# Set up flags
export LDFLAGS="$EM_FORGE_SIDE_MODULE_LDFLAGS"
export CFLAGS="$EM_FORGE_SIDE_MODULE_CFLAGS"


# # is cmake installed in the build prefix?
# # check the conda-meta.yaml file for the cmake dependency
# if compgen -G "${BUILD_PREFIX}/conda-meta/cmake-*.json" > /dev/null; then

#   echo "CMake is installed, setting up custom FindPython.cmake"

#   # we overwrite the FindPython.cmake **IN THE BUILD PREFIX**
#   CUSTOM_FIND_PYTHON=$BUILD_PREFIX/share/cross-python/FindPython.cmake

#   # guess the cmake version (ie 4.0.1)
#   CMAKE_VERSION=""
#   if command -v cmake &> /dev/null; then
#       # cmake is found, try to get the version
#       if CMAKE_VERSION_OUTPUT=$($BUILD_PREFIX/bin/cmake --version 2>&1); then
#           # Command succeeded
#           CMAKE_VERSION=$(echo "$CMAKE_VERSION_OUTPUT" | head -n 1 | cut -d ' ' -f 3)
#           echo "CMake version: $CMAKE_VERSION"
#       else
#           # Command failed for other reasons (e.g., bad arguments, corrupted binary)
#           echo "Error: 'cmake --version' failed."
#           echo "Output:"
#           echo "$CMAKE_VERSION_OUTPUT"
#           CMAKE_VERSION="unknown" # Set a default or error value
#       fi
#   else
#       # cmake is not found
#       # this is a problem, we cannot proceed
#       echo "Error: CMake is not installed in the build prefix."
#       exit 1
#   fi
#   # remove the patch version
#   CMAKE_VERSION=$(echo $CMAKE_VERSION | cut -d '.' -f 1-2)

#   CMAKE_MODULE_DIR="$BUILD_PREFIX/share/cmake-$CMAKE_VERSION/Modules"

#   # if the cmake-moduledir is not at the expected location
#   # we assume that this is an error
#   if [[ ! -d "$CMAKE_MODULE_DIR" ]]; then
#     echo "Error: CMake module directory $CMAKE_MODULE_DIR does not exist at the expected location."
#     echo "This might be an error on the emscripten-forge side."
#     echo "Please report this issue."
#     exit 1
#   fi

#   cp $CUSTOM_FIND_PYTHON $CMAKE_MODULE_DIR/FindPython.cmake

# else
#   echo "CMake is not installed, skipping custom FindPython.cmake setup"
# fi
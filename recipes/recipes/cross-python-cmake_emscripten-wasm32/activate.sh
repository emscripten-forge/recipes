#!/bin/bash


# is cmake installed in the build prefix?
# check the conda-meta.yaml file for the cmake dependency
if compgen -G "${BUILD_PREFIX}/conda-meta/cmake-*.json" > /dev/null; then

  echo "CMake is installed, setting up custom FindPython.cmake"

  # we overwrite the FindPython.cmake **IN THE BUILD PREFIX**
  CUSTOM_FIND_PYTHON=$BUILD_PREFIX/share/cross-python-cmake/FindPython.cmake

  # guess the cmake version (ie 4.0.1)
  CMAKE_VERSION=""
  if command -v cmake &> /dev/null; then
      # cmake is found, try to get the version
      if CMAKE_VERSION_OUTPUT=$($BUILD_PREFIX/bin/cmake --version 2>&1); then
          # Command succeeded
          CMAKE_VERSION=$(echo "$CMAKE_VERSION_OUTPUT" | head -n 1 | cut -d ' ' -f 3)
          echo "CMake version: $CMAKE_VERSION"
      else
          # Command failed for other reasons (e.g., bad arguments, corrupted binary)
          echo "Error: 'cmake --version' failed."
          echo "Output:"
          echo "$CMAKE_VERSION_OUTPUT"
          CMAKE_VERSION="unknown" # Set a default or error value
      fi
  else
      # cmake is not found
      # this is a problem, we cannot proceed
      echo "Error: CMake is not installed in the build prefix."
      exit 1
  fi
  # remove the patch version
  CMAKE_VERSION=$(echo $CMAKE_VERSION | cut -d '.' -f 1-2)

  CMAKE_MODULE_DIR="$BUILD_PREFIX/share/cmake-$CMAKE_VERSION/Modules"

  # if the cmake-moduledir is not at the expected location
  # we assume that this is an error
  if [[ ! -d "$CMAKE_MODULE_DIR" ]]; then
    echo "Error: CMake module directory $CMAKE_MODULE_DIR does not exist at the expected location."
    echo "This might be an error on the emscripten-forge side."
    echo "Please report this issue."
    exit 1
  fi

  cp $CUSTOM_FIND_PYTHON $CMAKE_MODULE_DIR/FindPython.cmake

else
  echo "CMake is not installed, skipping custom FindPython.cmake setup"
fi
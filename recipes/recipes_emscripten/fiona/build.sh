#!/bin/bash

# Note: This build will likely fail until GDAL is available in emscripten-forge
# The build script is provided for when GDAL support is added

${PYTHON} -m pip install . -vv --no-binary fiona
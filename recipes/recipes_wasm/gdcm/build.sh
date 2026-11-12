#!/bin/bash
set -exuo pipefail

mkdir -p build
cd build

# GDCM's python wrapping still uses FindPythonInterp / FindPythonLibs: point
# them at the build python and the emscripten python headers. The extension
# module is a side module, so it does not link libpython.
# LIBRARY_OUTPUT_PATH: the python wrapping copies gdcm.py / gdcmswig.py there
# after linking, but upstream never sets it (libraries go to build/bin).
TARGET_PYTHON_INCLUDE="${PREFIX}/include/python${PY_VER}"

emcmake cmake -GNinja \
    ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH \
    -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH \
    -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=BOTH \
    -DGDCM_BUILD_SHARED_LIBS=OFF \
    -DGDCM_BUILD_TESTING=OFF \
    -DGDCM_BUILD_APPLICATIONS=OFF \
    -DGDCM_BUILD_EXAMPLES=OFF \
    -DGDCM_WRAP_PYTHON=ON \
    -DGDCM_DEFAULT_PYTHON_VERSION="${PY_VER}" \
    -DPYTHON_EXECUTABLE="${BUILD_PREFIX}/bin/python" \
    -DPYTHON_INCLUDE_DIR="${TARGET_PYTHON_INCLUDE}" \
    -DPYTHON_INCLUDE_PATH="${TARGET_PYTHON_INCLUDE}" \
    -DPYTHON_LIBRARY="${TARGET_PYTHON_INCLUDE}/Python.h" \
    -DGDCM_NO_PYTHON_LIBS_LINKING=ON \
    -DGDCM_INSTALL_PYTHONMODULE_DIR="lib/python${PY_VER}/site-packages" \
    -DLIBRARY_OUTPUT_PATH="${PWD}/bin" \
    -DSWIG_EXECUTABLE="${BUILD_PREFIX}/bin/swig" \
    -DGDCM_WRAP_JAVA=OFF \
    -DGDCM_WRAP_CSHARP=OFF \
    -DGDCM_WRAP_PHP=OFF \
    -DGDCM_USE_VTK=OFF \
    -DGDCM_DOCUMENTATION=OFF \
    -DGDCM_PDF_DOCUMENTATION=OFF \
    -DGDCM_USE_SYSTEM_ZLIB=OFF \
    -DGDCM_USE_SYSTEM_EXPAT=OFF \
    -DGDCM_USE_SYSTEM_OPENSSL=OFF \
    -DGDCM_USE_SYSTEM_UUID=OFF \
    -DGDCM_USE_SYSTEM_JSON=OFF \
    -DGDCM_USE_SYSTEM_LIBXML2=OFF \
    -DGDCM_USE_SYSTEM_POPPLER=OFF \
    -DGDCM_USE_SYSTEM_SOCKETXX=OFF \
    -DGDCM_USE_SYSTEM_CHARLS=OFF \
    -DGDCM_USE_SYSTEM_OPENJPEG=OFF \
    -DGDCM_USE_SYSTEM_LJPEG=OFF \
    -DGDCM_USE_SYSTEM_PAPYRUS3=OFF \
    -DGDCM_USE_JPEGTURBO=OFF \
    -DGDCM_USE_JPEGLS=ON \
    -DGDCM_USE_PVRG=OFF \
    -DGDCM_USE_KAKADU=OFF \
    -DGDCM_USE_COREFOUNDATION_LIBRARY=OFF \
    -DGDCM_HAVE_PTHREAD_H=OFF \
    -DOPJ_USE_THREAD=OFF \
    ..

ninja install

# Remove .la files if any
find "${PREFIX}" -name '*.la' -delete 2>/dev/null || true

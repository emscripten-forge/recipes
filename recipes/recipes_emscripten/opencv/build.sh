#!/bin/bash

set -ex

mkdir build
cd build

# Configure step
emcmake cmake ${CMAKE_ARGS} \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH=${PREFIX} \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DBUILD_SHARED_LIBS=OFF \
    -DWITH_FFMPEG=OFF \
    -DWITH_GTK=OFF \
    -DWITH_QT=OFF \
    -DWITH_OPENEXR=OFF \
    -DWITH_JASPER=OFF \
    -DWITH_TIFF=OFF \
    -DWITH_WEBP=OFF \
    -DWITH_OPENMP=OFF \
    -DWITH_PTHREADS_PF=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_TESTS=OFF \
    -DBUILD_PERF_TESTS=OFF \
    -DBUILD_opencv_apps=OFF \
    -DBUILD_opencv_python2=OFF \
    -DBUILD_opencv_python3=ON \
    -DPYTHON3_EXECUTABLE=${PYTHON} \
    -DPYTHON3_INCLUDE_DIR=${PREFIX}/include/python${PY_VER} \
    -DPYTHON3_LIBRARY=${PREFIX}/lib/libpython${PY_VER}.a \
    -DPYTHON3_NUMPY_INCLUDE_DIRS=${BUILD_PREFIX}/lib/python${PY_VER}/site-packages/numpy/_core/include \
    -DWITH_EIGEN=OFF \
    -DWITH_LAPACK=OFF \
    -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
    -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
    -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
    ..

# Build step
emmake ninja install

# Install Python bindings manually if they weren't installed automatically
if [ -f lib/python3/cv2*.so ]; then
    mkdir -p ${PREFIX}/lib/python${PY_VER}/site-packages/
    cp lib/python3/cv2*.so ${PREFIX}/lib/python${PY_VER}/site-packages/
fi
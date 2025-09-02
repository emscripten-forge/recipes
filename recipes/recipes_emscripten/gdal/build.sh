#!/bin/bash

mkdir -p build && cd build

emcmake cmake ${CMAKE_ARGS} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=${PREFIX} \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DBUILD_SHARED_LIBS=OFF \
      -DCMAKE_PROJECT_INCLUDE=${RECIPE_DIR}/overwriteProp.cmake \
      -DBUILD_TESTING=OFF \
      -DGDAL_BUILD_APPS=OFF \
      -DBUILD_PYTHON_BINDINGS=OFF \
      -DBUILD_JAVA_BINDINGS=OFF \
      -DBUILD_CSHARP_BINDINGS=OFF \
      -DGDAL_USE_TIFF=ON \
      -DGDAL_USE_JPEG=ON \
      -DGDAL_USE_PNG=ON \
      -DGDAL_USE_ZLIB=ON \
      -DGDAL_USE_SQLITE3=ON \
      -DGDAL_USE_EXPAT=ON \
      -DGDAL_USE_LIBXML2=ON \
      -DGDAL_USE_GEOS=ON \
      -DGDAL_USE_PROJ=ON \
      -DGDAL_USE_HDF5=ON \
      -DGDAL_USE_NETCDF=ON \
      -DGDAL_USE_CURL=OFF \
      -DGDAL_USE_OPENSSL=OFF \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
      ..

emmake make -j${CPU_COUNT}

emmake make install -j${CPU_COUNT}
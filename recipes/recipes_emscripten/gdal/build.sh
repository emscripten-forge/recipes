#!/bin/bash

mkdir -p build && cd build

emcmake cmake ${CMAKE_ARGS} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=${PREFIX} \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DBUILD_SHARED_LIBS=OFF \
      -DCMAKE_PROJECT_INCLUDE=${RECIPE_DIR}/overwriteProp.cmake \
      -DBUILD_TESTING=OFF \
      -DBUILD_APPS=OFF \
      -DGDAL_BUILD_APPS=OFF \
      -DBUILD_PYTHON_BINDINGS=OFF \
      -DBUILD_JAVA_BINDINGS=OFF \
      -DBUILD_CSHARP_BINDINGS=OFF \
      -DGDAL_USE_EXTERNAL_LIBS=ON \
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
      -DGDAL_ENABLE_DRIVER_GIF=OFF \
      -DGDAL_ENABLE_DRIVER_WEBP=OFF \
      -DTIFF_INCLUDE_DIR=$PREFIX/include \
      -DTIFF_LIBRARY=$PREFIX/lib/libtiff.a \
      -DJPEG_INCLUDE_DIR=$PREFIX/include \
      -DJPEG_LIBRARY=$PREFIX/lib/libjpeg.a \
      -DPNG_PNG_INCLUDE_DIR=$PREFIX/include \
      -DPNG_LIBRARY=$PREFIX/lib/libpng.a \
      -DZLIB_INCLUDE_DIR=$PREFIX/include \
      -DZLIB_LIBRARY=$PREFIX/lib/libz.a \
      -DSQLite3_INCLUDE_DIR=$PREFIX/include \
      -DSQLite3_LIBRARY=$PREFIX/lib/libsqlite3.a \
      -DEXPAT_INCLUDE_DIR=$PREFIX/include \
      -DEXPAT_LIBRARY=$PREFIX/lib/libexpat.a \
      -DLIBXML2_INCLUDE_DIR=$PREFIX/include \
      -DLIBXML2_LIBRARIES=$PREFIX/lib/libxml2.a \
      -DGEOS_INCLUDE_DIR=$PREFIX/include \
      -DGEOS_LIBRARY=$PREFIX/lib/libgeos.a \
      -DPROJ_INCLUDE_DIR=$PREFIX/include \
      -DPROJ_LIBRARY=$PREFIX/lib/libproj.a \
      -DHDF5_INCLUDE_DIR=$PREFIX/include \
      -DHDF5_LIBRARIES="$PREFIX/lib/libhdf5.a" \
      -DNETCDF_INCLUDE_DIR=$PREFIX/include \
      -DNETCDF_LIBRARY=$PREFIX/lib/libnetcdf.a \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
      ..

emmake make -j${CPU_COUNT}

emmake make install -j${CPU_COUNT}
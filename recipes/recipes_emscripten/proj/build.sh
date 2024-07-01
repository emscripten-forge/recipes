#!/bin/bash

mkdir -p build

cd build

export SQLITE_DIR=${BUILD_PREFIX}/lib/sqlite3.40.0
export SQLITE=${BUILD_PREFIX}/include

# build without curl as stated in
# https://github.com/OSGeo/PROJ/issues/1957
emcmake cmake ${CMAKE_ARGS} .. \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=OFF \
      -DBUILD_TESTING=OFF \
      -DCMAKE_INSTALL_PREFIX=${PREFIX} \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DENABLE_CURL=OFF \
      -DENABLE_TIFF=OFF \
      -DBUILD_PROJSYNC=OFF \
      -DSQLite3_INCLUDE_DIR=${SQLITE} \
      -DSQLite3_LIBRARY=${SQLITE} \

#emmake make -j${CPU_COUNT} ${VERBOSE_CM}

#emmake make install -j${CPU_COUNT}

#ACTIVATE_DIR=${PREFIX}/etc/conda/activate.d
#DEACTIVATE_DIR=${PREFIX}/etc/conda/deactivate.d
#mkdir -p ${ACTIVATE_DIR}
#mkdir -p ${DEACTIVATE_DIR}

#cp ${RECIPE_DIR}/scripts/activate.sh ${ACTIVATE_DIR}/proj4-activate.sh
#cp ${RECIPE_DIR}/scripts/deactivate.sh ${DEACTIVATE_DIR}/proj4-deactivate.sh
#cp ${RECIPE_DIR}/scripts/activate.csh ${ACTIVATE_DIR}/proj4-activate.csh
#cp ${RECIPE_DIR}/scripts/deactivate.csh ${DEACTIVATE_DIR}/proj4-deactivate.csh
#cp ${RECIPE_DIR}/scripts/activate.fish ${ACTIVATE_DIR}/proj4-activate.fish
#cp ${RECIPE_DIR}/scripts/deactivate.fish ${DEACTIVATE_DIR}/proj4-deactivate.fish

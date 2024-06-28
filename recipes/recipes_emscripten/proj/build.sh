#!/bin/bash

mkdir -p build && cd build

if [[ "$CONDA_BUILD_CROSS_COMPILATION" != "1" ]]; then
    EXE_SQLITE3=${PREFIX}/bin/sqlite3
else
    EXE_SQLITE3=${BUILD_PREFIX}/bin/sqlite3
fi

emcmake cmake ${CMAKE_ARGS} \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=ON \
      -DCMAKE_INSTALL_PREFIX=${PREFIX} \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DEXE_SQLITE3=${EXE_SQLITE3} \
      ${SRC_DIR}

emmake make -j${CPU_COUNT} ${VERBOSE_CM}

emmake make install -j${CPU_COUNT}

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

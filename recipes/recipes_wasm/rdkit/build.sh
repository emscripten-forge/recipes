#!/bin/bash
set -ex

# cairo-static: link cairo together with all its static dependencies
CAIRO_LIBS="${PREFIX}/lib/libcairo.a"
for l in fontconfig expat freetype png16 z pixman-1; do
  CAIRO_LIBS="${CAIRO_LIBS};${PREFIX}/lib/lib${l}.a"
done
NUMPY_INCLUDE=$(${PYTHON} -c "import numpy; print(numpy.get_include())")
NANOBIND_CMAKE_DIR=$(python -m nanobind --cmake_dir)

mkdir -p build
cd build

cmake ${CMAKE_ARGS} .. -GNinja \
  -DCMAKE_PROJECT_INCLUDE=${RECIPE_DIR}/overwriteProp.cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=${PREFIX} \
  -DCMAKE_PREFIX_PATH=${PREFIX} \
  -DPython_EXECUTABLE=${PYTHON} \
  -DPython_INCLUDE_DIR=${PREFIX}/include/python${PY_VER} \
  -DPython_LIBRARY=${PREFIX}/lib/libpython${PY_VER}.a \
  -DPython_NumPy_INCLUDE_DIR=${NUMPY_INCLUDE} \
  -DPYTHON_INSTDIR=${SP_DIR} \
  -Dnanobind_DIR=${NANOBIND_CMAKE_DIR} \
  -DBoost_DIR=${RECIPE_DIR}/boost-cmake \
  -DBoost_INCLUDE_DIR=${PREFIX}/include \
  -DRDK_INSTALL_INTREE=OFF \
  -DRDK_BUILD_NANOBIND_WRAPPERS=ON \
  -DRDK_BUILD_BOOST_PYTHON_WRAPPERS=OFF \
  -DRDK_INSTALL_STATIC_LIBS=OFF \
  -DRDK_BUILD_CPP_TESTS=OFF \
  -DRDK_BUILD_THREADSAFE_SSS=OFF \
  -DRDK_TEST_MULTITHREADED=OFF \
  -DRDK_OPTIMIZE_POPCNT=OFF \
  -DRDK_USE_BOOST_SERIALIZATION=OFF \
  -DRDK_USE_BOOST_IOSTREAMS=OFF \
  -DRDK_BUILD_COORDGEN_SUPPORT=OFF \
  -DRDK_BUILD_MAEPARSER_SUPPORT=OFF \
  -DRDK_BUILD_CHEMDRAW_SUPPORT=OFF \
  -DRDK_BUILD_PUBCHEMSHAPE_SUPPORT=OFF \
  -DRDK_BUILD_CAIRO_SUPPORT=ON \
  -DCAIRO_INCLUDE_DIRS=${PREFIX}/include/cairo \
  "-DCAIRO_LIBRARIES=${CAIRO_LIBS}" \
  -DRDK_BUILD_FREETYPE_SUPPORT=ON \
  -DRDK_INSTALL_COMIC_FONTS=OFF \
  -DFETCHCONTENT_SOURCE_DIR_BETTER_ENUMS=${SRC_DIR}/better_enums \
  -DURFLIB_DIR=${SRC_DIR}/External/RingFamilies/RingDecomposerLib/src/RingDecomposerLib

ninja -j${CPU_COUNT}
ninja install

# only the runtime is needed in the browser: drop headers, cmake files,
# docs/example notebooks and the Contrib sources (>80 MiB); keep share/RDKit/Data
rm -rf ${PREFIX}/include/rdkit ${PREFIX}/lib/cmake/rdkit
rm -rf ${PREFIX}/share/RDKit/Docs ${PREFIX}/share/RDKit/Contrib

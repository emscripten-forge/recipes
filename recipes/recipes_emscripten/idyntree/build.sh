#!/bin/sh

mkdir build
cd build

# See https://github.com/microsoft/vcpkg/pull/11753
export CMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH:/

find $PREFIX

env

sudo rm -rf /bin/swig*


cmake ${CMAKE_ARGS} -GNinja .. \
      -DBUILD_SHARED_LIBS:BOOL=OFF \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=$PREFIX \
      -DBUILD_TESTING:BOOL=${BUILD_TESTING} \
      -DIDYNTREE_USES_IPOPT:BOOL=OFF \
      -DIDYNTREE_USES_OSQPEIGEN:BOOL=OFF \
      -DIDYNTREE_USES_IRRLICHT:BOOL=OFF \
      -DIDYNTREE_USES_ASSIMP:BOOL=OFF \
      -DIDYNTREE_USES_MATLAB:BOOL=OFF \
      -DIDYNTREE_USES_PYTHON:BOOL=ON \
      -DIDYNTREE_USES_OCTAVE:BOOL=OFF \
      -DIDYNTREE_USES_LUA:BOOL=OFF \
      -DIDYNTREE_COMPILES_YARP_TOOLS:BOOL=OFF \
      -DPython3_EXECUTABLE:PATH=$BUILD_PREFIX/bin/python \
      -DIDYNTREE_DETECT_ACTIVE_PYTHON_SITEPACKAGES:BOOL=ON \
      -DIDYNTREE_PYTHON_PIP_METADATA_INSTALLER=conda \
      -DPython3_INCLUDE_DIR:PATH=$PREFIX/include/`ls $PREFIX/include | grep "python\|pypy"` \
      -DLIBXML2_INCLUDE_DIR:PATH=$PREFIX/include/libxml2 \
      -DLIBXML2_LIBRARY=$PREFIX/lib/libxml2.a \
      -DPython3_NumPy_INCLUDE_DIR:PATH=$PREFIX/lib/`ls $PREFIX/lib/ | grep "python\|pypy"`/site-packages/numpy/core/include
      -DIDYNTREE_COMPILES_TOOLS:BOOL=OFF

ninja
ninja install
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR}" != "" ]]; then
  ctest --output-on-failure -C Release
fi

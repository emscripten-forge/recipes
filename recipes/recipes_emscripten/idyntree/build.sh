#!/bin/sh

mkdir build
cd build

# See https://github.com/microsoft/vcpkg/pull/11753
export CMAKE_PREFIX_PATH=$PREFIX:/
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX:/
export CMAKE_FIND_ROOT_PATH=$PREFIX

echo "=====> CMAKE_ARGS: ${CMAKE_ARGS}"

cmake ${CMAKE_ARGS} -GNinja .. \
      -DCMAKE_BUILD_TYPE=Release \
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
      -DPython3_EXECUTABLE:PATH=$PYTHON \
      -DIDYNTREE_DETECT_ACTIVE_PYTHON_SITEPACKAGES:BOOL=ON \
      -DIDYNTREE_PYTHON_PIP_METADATA_INSTALLER=conda

cmake --build . --config Release 
cmake --build . --config Release --target install
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR}" != "" ]]; then
  ctest --output-on-failure -C Release
fi

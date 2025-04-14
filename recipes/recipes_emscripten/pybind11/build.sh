
unset PYTHON
mkdir build
cd build



cp ${RECIPE_DIR}/"FindPythonLibsNew.cmake" ${SRC_DIR}/tools/



echo "PY_VER=$PY_VER"


if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS specific command
    sed -i '' "s|\${py_version}|$PY_VER|g"  ${SRC_DIR}/tools/FindPythonLibsNew.cmake
else
    # Non-macOS (Linux or others) specific command
    sed -i "s|\${py_version}|$PY_VER|g" ${SRC_DIR}/tools/FindPythonLibsNew.cmake
fi



# print contents of FindPythonLibsNew.cmake
cat ${SRC_DIR}/tools/FindPythonLibsNew.cmake


# Configure step
cmake ${CMAKE_ARGS} ..              \
    -GNinja                         \
    -DCMAKE_BUILD_TYPE=Release      \
    -DCMAKE_PREFIX_PATH=$PREFIX     \
    -DPYBIND11_INSTALL=ON           \
    -DPYBIND11_TEST=OFF             \
    -DPYBIND11_NOPYTHON=ON          \
    -DCMAKE_INSTALL_PREFIX=$PREFIX 

# Build step
ninja install

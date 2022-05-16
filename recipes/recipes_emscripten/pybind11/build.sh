
unset PYTHON
mkdir build
cd build


if [[ $target_platform == "emscripten-32" ]]; then
    cp ${RECIPE_DIR}/"FindPythonLibsNew.cmake" ${SRC_DIR}/tools/
fi



# Configure step
cmake ${CMAKE_ARGS} ..              \
    -GNinja                         \
    -DCMAKE_BUILD_TYPE=Release      \
    -DCMAKE_PREFIX_PATH=$PREFIX     \
    -DPYBIND11_INSTALL=ON           \
    -DPYBIND11_TEST=OFF             \
    -DPYBIND11_NOPYTHON=ON          \
    -DCMAKE_INSTALL_PREFIX=$PREFIX  \

# Build step
ninja install

mkdir build
cd build
mkdir -p $PREFIX

# Configure step
cmake ${CMAKE_ARGS} ..                    \
    -GNinja                               \
    -DCMAKE_PREFIX_PATH:PATH=${PREFIX}    \
    -DCMAKE_INSTALL_PREFIX:PATH=${PREFIX} \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON  \
    -DCMAKE_BUILD_TYPE=Release

ninja install

# Copy wasm files also
cp src/main/*.wasm $PREFIX/bin/

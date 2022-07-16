mkdir build
cd build
mkdir -p $PREFIX

# Configure step
cmake ${CMAKE_ARGS} ..                    \
    -GNinja                               \
    -DCMAKE_PREFIX_PATH:PATH=${PREFIX}    \ 
    -DCMAKE_INSTALL_PREFIX:PATH=${PREFIX} \
    -DCMAKE_BUILD_TYPE=Release
    
ninja install

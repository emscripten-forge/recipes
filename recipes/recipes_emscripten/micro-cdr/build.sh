mkdir build && cd build
# Configure step
emcmake cmake -DCMAKE_BUILD_TYPE=Release -H. -B ./ -S ../ ${CMAKE_ARGS}
# Build step
emmake make install -j8

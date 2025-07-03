mkdir build && cd build
# Configure step
emcmake cmake -DCMAKE_BUILD_TYPE=Release -S .. -B . -DUCDR_SUPERBUILD=OFF -DUCDR_ISOLATED_INSTALL=OFF ${CMAKE_ARGS}
# Build step
emmake make install -j8

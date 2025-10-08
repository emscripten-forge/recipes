mkdir build
cd build

# Configure step
emcmake cmake ${CMAKE_ARGS} ..      \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DCMAKE_PREFIX_PATH:PATH=${PREFIX} \
    -DCMAKE_INSTALL_PREFIX:PATH=${PREFIX} \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_BUILD_TYPE=Release \
    -DHIGHFIVE_UNIT_TESTS=OFF \
    -DHIGHFIVE_EXAMPLES=OFF \
    -DHIGHFIVE_USE_BOOST=OFF \
    -DHIGHFIVE_USE_INSTALL_DEPS=OFF

# Build step
emmake make
emmake make install

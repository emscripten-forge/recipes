emcmake cmake \
    -Bbuild \
    -DCMAKE_INSTALL_LIBDIR=${PREFIX}/lib \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DCMAKE_PREFIX_PATH=${PREFIX} \
    -DHDF5_DIR=${PREFIX}/cmake \
    -DMATIO_BUILD_TESTING=OFF \
    -DZLIB_INCLUDE_DIR=${PREFIX}/include \
    -DZLIB_LIBRARY=${PREFIX}/lib/libz.a

cd build
emmake make
emmake make install

mkdir -p ${PREFIX}/lib/pkgconfig
cp matio.pc ${PREFIX}/lib/pkgconfig/matio.pc

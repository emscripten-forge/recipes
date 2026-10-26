mkdir build
cd build

# remove all the fake pythons
rm -f $PREFIX/bin/python*


export CMAKE_PREFIX_PATH=$PREFIX
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX

echo "PYTHON VER" $PY_VER



PYTHON_LIBRARIES="$PREFIX/lib/libbz2.a;\
$PREFIX/lib/libz.a;\
$PREFIX/lib/libsqlite3.a;\
$PREFIX/lib/libffi.a;\
$PREFIX/lib/libzstd.a;\
$PREFIX/lib/libssl.a;\
$PREFIX/lib/libcrypto.a;\
$PREFIX/lib/liblzma.a;\
$PREFIX/lib/python${PY_VER}/static/libexpat.a;\
$PREFIX/lib/python${PY_VER}/static/libmpdec.a;\
$PREFIX/lib/python${PY_VER}/static/libHacl_Hash_BLAKE2.a;\
$PREFIX/lib/python${PY_VER}/static/libHacl_Hash_MD5.a;\
$PREFIX/lib/python${PY_VER}/static/libHacl_Hash_SHA1.a;\
$PREFIX/lib/python${PY_VER}/static/libHacl_Hash_SHA2.a;\
$PREFIX/lib/python${PY_VER}/static/libHacl_Hash_SHA3.a;\
$PREFIX/lib/libpython$PY_VER.a;"


# Configure step    
cmake ${CMAKE_ARGS} ..                                      \
    -GNinja                                                 \
    -DCMAKE_BUILD_TYPE=Release                              \
    -DCMAKE_PREFIX_PATH=$PREFIX                             \
    -DCMAKE_INSTALL_PREFIX=$PREFIX                          \
    -DXEUS_PYWRAP_INSTALL_XEUS_ECHO_KERNEL=OFF              \
    -DXEUS_PYWRAP_INSTALL_XEUS_SHAKESPEARELANG_KERNEL=OFF   \
    -DCMAKE_BUILD_TYPE=Release                        \
    -DCMAKE_PREFIX_PATH=$PREFIX                       \
    -DCMAKE_INSTALL_PREFIX=$PREFIX                    \
    -DPYTHON_LIBRARIES="$PYTHON_LIBRARIES"            \
    -DXEUS_PYWRAP_PYTHON_SITEARCH=$PREFIX/lib/python$PY_VER/site-packages



# Build step
ninja

ninja install

# remove raw-kernel
rm -rf $PREFIX/share/jupyter/kernels/xpython-raw/


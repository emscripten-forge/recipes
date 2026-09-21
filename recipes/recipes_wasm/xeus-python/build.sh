mkdir build
cd build

# remove all the fake pythons
rm -f $PREFIX/bin/python*


export CMAKE_PREFIX_PATH=$PREFIX
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX

if [[ $target_platform == "emscripten-wasm32" ]]; then
    export USE_WASM=ON
else
    export USE_WASM=OFF
fi


# assert that py-ver is set
if [ -z "$PY_VER" ]; then
    echo "PY_VER is not set"
    exit 1
fi

# check that libpython$PY_VER.a exists
if [ ! -f "$PREFIX/lib/libpython$PY_VER.a" ]; then
    echo "libpython$PY_VER.a not found in $PREFIX/lib"
    exit 1
fi


PYTHON_LIBRARIES="$PREFIX/lib/libbz2.a;\
$PREFIX/lib/libz.a;\
$PREFIX/lib/libsqlite3.a;\
$PREFIX/lib/libffi.a;\
$PREFIX/lib/libzstd.a;\
$PREFIX/lib/libssl.a;\
$PREFIX/lib/libcrypto.a;\
$PREFIX/lib/liblzma.a;\
$PREFIX/lib/libexpat.a;\
$PREFIX/lib/libmpdec.a;\
$PREFIX/lib/libHacl_Hash_BLAKE2.a;\
$PREFIX/lib/libHacl_Hash_MD5.a;\
$PREFIX/lib/libHacl_Hash_SHA1.a;\
$PREFIX/lib/libHacl_Hash_SHA2.a;\
$PREFIX/lib/libHacl_Hash_SHA3.a;\
$PREFIX/lib/libpython$PY_VER.a;"






# Configure step
cmake ${CMAKE_ARGS} ..                                \
    -GNinja                                           \
    -DCMAKE_BUILD_TYPE=Release                        \
    -DCMAKE_PREFIX_PATH=$PREFIX                       \
    -DCMAKE_INSTALL_PREFIX=$PREFIX                    \
    -DPYTHON_LIBRARIES="$PYTHON_LIBRARIES"            \
    -DPYBIND11_PYTHON_VERSION=$PY_VER                 

# Build step
ninja

ninja install

# remove raw-kernel
rm -rf $PREFIX/share/jupyter/kernels/xpython-raw/


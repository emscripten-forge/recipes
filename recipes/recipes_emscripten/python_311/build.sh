#export CPYTHON_ABI_FLAGS=""
export PYMAJOR=3
export PYMINOR=11
export LIB="libpython$PYMAJOR.$PYMINOR.a"

export PLATFORM_TRIPLET=wasm32-emscripten
export SYSCONFIG_NAME=_sysconfigdata__emscripten_wasm32-emscripten


export OPTFLAGS=-O2
export CFLAGS_BASE="$OPTFLAGS $DBGFLAGS -fPIC $EXTRA_CFLAGS  -I$PREFIX/include"
export LDFLAGS_BASE="$OPTFLAGS $DBGFLAGS $DBG_LDFLAGS  -s WASM_BIGINT $EXTRA_LDFLAGS -L$PREFIX/lib -lffi -lz -luuid -lssl -lcrypto"
export BUILD_PYTHON="$BUILD_PREFIX/bin/python3.11"
#export PYTHON_FOR_BUILD=$BUILD_PYTHON

export _PYTHON_HOST_PLATFORM=$PLATFORM_TRIPLET
export _PYTHON_SYSCONFIGDATA_NAME=_sysconfigdata__emscripten_wasm32-emscripten
export _PYTHON_PROJECT_BASE=$(pwd)


PYTHON_CFLAGS="$CFLAGS_BASE -DPY_CALL_TRAMPOLINE"

#export BUILDEXEEXT=""
#export EXEEXT=""
export CONFIG_SITE=$(pwd)/Tools/wasm/config.site-wasm32-emscripten
if true; then

CONFIG_SITE=./Tools/wasm/config.site-wasm32-emscripten READELF=true emconfigure \
    ./configure \
        CFLAGS="${PYTHON_CFLAGS}" \
        CPPFLAGS="-sUSE_BZIP2=1 -sUSE_ZLIB=1" \
        LDFLAGS="-L${PREFIX}/lib -lffi -sWASM_BIGINT" \
        PLATFORM_TRIPLET="$PLATFORM_TRIPLET" \
        --without-pymalloc \
        --disable-shared \
        --disable-ipv6 \
        --enable-big-digits=30 \
        --enable-optimizations \
        --host=wasm32-unknown-emscripten \
        --build=$(bash $(pwd)/config.guess) \
        --prefix=$PREFIX  \
        --with-build-python=$BUILD_PREFIX/bin/python3.11


fi

cp  $RECIPE_DIR/Setup.local Modules
export _PYTHON_SYSCONFIGDATA_NAME=_sysconfigdata__emscripten_wasm32-emscripten
make regen-frozen


EMCC=$(which emcc)
EMAR=$(which emar)

# make backup of original files
cp $EMCC $EMCC.bak
cp $EMAR $EMAR.bak

# add  `export PYTHON=$BUILD_PREFIX/bin/python3.11` to both files
sed -i '' '1s/^/export PYTHON=$BUILD_PREFIX\/bin\/python3.11\n/' $EMCC
sed -i '' '1s/^/export PYTHON=$BUILD_PREFIX\/bin\/python3.11\n/' $EMAR


function cleanup {
  # restore original files
    mv $EMCC.bak $EMCC
    mv $EMAR.bak $EMAR
}

trap cleanup EXIT

export _PYTHON_SYSCONFIGDATA_NAME=_sysconfigdata__emscripten_wasm32-emscripten


# # export PYTHON=$BUILD_PREFIX/bin/python3.11
# # export EMSDK_PYTHON=$PYTHON
# # echo "PYTHON: $PYTHON"

emmake make CROSS_COMPILE=yes $LIB -j8

export _PYTHON_SYSCONFIGDATA_NAME=_sysconfigdata__emscripten_wasm32-emscripten

emmake make  CROSS_COMPILE=yes inclinstall libinstall $LIB -j 8 

emmake make install CROSS_COMPILE=yes inclinstall libinstall $LIB -j 8
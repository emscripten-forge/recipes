#!/bin/bash

cp $RECIPE_DIR/patches/configure .

PYTHON=${BUILD_PREFIX}/bin/python3.11

export DBGFLAGS=-g0
export OPTFLAGS=-O2
export CFLAGS_BASE="${DBGFLAGS} ${DBGFLAGS} -fPIC -Wno-implicit-function-declaration"
export PYTHON_CFLAGS=${CFLAGS_BASE}


export MULTIARCH=wasm32-emscripten
export PYVERSION=$PKG_VERSION
export PLATFORM_TRIPLET=wasm32-emscripten
export SYSCONFIG_NAME=_sysconfigdata__emscripten_$PLATFORM_TRIPLET

echo "PYVERSION" $PYVERSION
echo "EMSCRIPTEN_VERSION" $EMSCRIPTEN_VERSION
echo "PLATFORM_TRIPLET" $PLATFORM_TRIPLET


LIB=libpython3.11.a
 


if [[ $target_platform == "emscripten-32" ]]; then
    cp ${RECIPE_DIR}/config/config.site .

    CONFIG_SITE=./config.site READELF=true emconfigure \
      ./configure \
          CFLAGS="${PYTHON_CFLAGS}" \
          CPPFLAGS="-I${PREFIX}/include" \
          LDFLAGS="-L${PREFIX}/lib -lffi -lz -sWASM_BIGINT" \
          PLATFORM_TRIPLET=$PLATFORM_TRIPLET \
          MULTIARCH=$MULTIARCH \
          --without-pymalloc \
          --disable-shared \
          --disable-ipv6 \
          --enable-big-digits=30 \
          --enable-optimizations \
          --host=wasm32-unknown-emscripten\
          --build=$(./config.guess) \
          --prefix=${PREFIX}  \
    

    cp ${RECIPE_DIR}/config/Setup.local ./Modules/

    cat ${RECIPE_DIR}/config/pyconfig.undefs.h >> ./pyconfig.h


    emmake make CROSS_COMPILE=yes ${LIB} -j8


    sed -i -e 's/libinstall:.*/libinstall:/' Makefile; 
    
    # emmake make PYTHON_FOR_BUILD=${BUILD_PREFIX}/bin/python3.11 CROSS_COMPILE=yes inclinstall libinstall ${LIB} 
    emmake make PYTHON_FOR_BUILD=${BUILD_PREFIX}/bin/python3.11 CROSS_COMPILE=yes inclinstall libinstall bininstall ${LIB} 
    cp ${LIB}  ${PREFIX}/lib/ 

    emmake make CROSS_COMPILE=yes -j8

    # replace:
    #  "some/long/path/containing_the_build_dir/emcc"  with "emcc"
    #  "some/long/path/containing_the_build_dir/emar"  with "emar"
    #  "some/long/path/containing_the_build_dir/em++"  with "em++"
    FNAME_IN="build/lib.emscripten-3.10/$SYSCONFIG_NAME.py" 
    FNAME_OUT="build/lib.emscripten-3.10/$SYSCONFIG_NAME.py"
    $PYTHON $RECIPE_DIR/patch_sysconfigdata.py \
        --fname-in $FNAME_IN \
        --fname-out $FNAME_OUT \
        
    cp build/lib.emscripten-3.10/$SYSCONFIG_NAME.py ${PREFIX}/lib/python3.11/ 

    # CHANGE PLATTFORM TRIPLET IN SYSCONFIG
    sed -i "s/-lffi -lz/ /g"    ${PREFIX}/lib/python3.11/$SYSCONFIG_NAME.py
    # sed -i "s/'SHLIB_SUFFIX': '.so',/'SHLIB_SUFFIX': '.cpython-310-wasm32-emscripten.so',/g"  ${PREFIX}/lib/python3.11/_sysconfigdata__emscripten_.py

    # install/copy sysconfig to a place where cross-python expects the sysconfig
    mkdir -p ${PREFIX}/etc/conda
    cp ${PREFIX}/lib/python3.11/$SYSCONFIG_NAME.py ${PREFIX}/etc/conda/

    # cleanup
    pushd ${PREFIX}
    find . grep -E "(/__pycache__$|\.pyc$|\.pyo$)" | xargs rm -rf
    popd

    # cleanup
    pushd ${PREFIX}
    find . grep -E "(/__pycache__$|\.pyc$|\.pyo$)" | xargs rm -rf
    popd

    # remove the removal modules
    pushd ${PREFIX}/lib/python3.11/
    rm -rf `cat ${RECIPE_DIR}/config/remove_modules.txt`
    popd

    # unwanted test dirs
    rm -rf ${PREFIX}/lib/python3.11/ctypes/test
    rm -rf ${PREFIX}/lib/python3.11/distutils/test
    rm -rf ${PREFIX}/lib/python3.11/sqlite3/test
    rm -rf ${PREFIX}/lib/python3.11/unittest/tests

    # remove broken links but keep python3.11 binary
    # and the non-broken link to it
    rm  ${PREFIX}/bin/2to3
    rm  ${PREFIX}/bin/idle3
    rm  ${PREFIX}/bin/pydoc3
    rm  ${PREFIX}/bin/python3-config

    # remove broken links
    rm -rf ${PREFIX}/lib/pkgconfig 
    
else
    mkdir -p build
    pushd build
    ../configure -C \
        --prefix=$PREFIX

    make -j$(nproc)
    make install
    popd
fi

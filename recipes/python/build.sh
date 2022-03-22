#!/bin/bash


export DBGFLAGS=-g0
export OPTFLAGS=-O2
export CFLAGS_BASE="${DBGFLAGS} ${DBGFLAGS} -fPIC"

export PYTHON_CFLAGS=${CFLAGS_BASE}


LIB=libpython3.10.a
SYSCONFIG_NAME=_sysconfigdata__emscripten_

if [[ $target_platform == "emscripten-32" ]]; then
    cp ${RECIPE_DIR}/config.site .

    CONFIG_SITE=./config.site READELF=true emconfigure \
      ./configure \
          CFLAGS="${PYTHON_CFLAGS}" \
          CPPFLAGS="-I${PREFIX}/include" \
          LDFLAGS="-L${PREFIX}/lib -lffi -lz" \
          --without-pymalloc \
          --disable-shared \
          --disable-ipv6 \
          --enable-big-digits=30 \
          --enable-optimizations \
          --host=wasm32-unknown-emscripten\
          --build=$(./config.guess) \
          --prefix=${PREFIX}  \
    

    cp ${RECIPE_DIR}/Setup.local ./Modules/

    cat ${RECIPE_DIR}/pyconfig.undefs.h >> ./pyconfig.h


    emmake make CROSS_COMPILE=yes ${LIB} -j8


    sed -i -e 's/libinstall:.*/libinstall:/' Makefile; 
    
    emmake make PYTHON_FOR_BUILD=${BUILD_PREFIX}/bin/python3.10 CROSS_COMPILE=yes inclinstall libinstall ${LIB} 
    cp ${LIB}  ${PREFIX}/lib/ 



    # # emmake make install
    # echo "LS"
    # ls
    # ls Modules
    # mkdir -p $PREFIX/lib/python_internal
    # cp -t $PREFIX/lib/python_internal Modules/_decimal/libmpdec/libmpdec.a
    # cp -t $PREFIX/lib/python_internal Modules/expat/libexpat.a

else
    mkdir -p build
    pushd build
    ../configure -C \
        --prefix=$PREFIX

    make -j$(nproc)
    make install
    popd
fi

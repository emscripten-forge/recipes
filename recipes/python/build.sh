#!/usr/bin/env bash



# Following is needed for building extensions like zlib
CPPFLAGS=${CPPFLAGS}"-I${PREFIX}/include"

export LDFLAGS="-L ${PREFIX}/lib"
# -lffi -lsqlite3 -lbz2"
export CPPFLAGS CFLAGS CXXFLAGS LDFLAGS

if [[ $target_platform == "emscripten-32" ]]; then


    # use our own config site
    cp ${RECIPE_DIR}/conda.config.site-wasm32-emscripten conda.config.site-wasm32-emscripten

    # create build dir
    mkdir -p builddir/emscripten-browser
    pushd builddir/emscripten-browser


    ##########
    # configure / makefile 
    # exports PYTHON as python.html
    ###############
    unset PYTHON
    # export PYTHON=${BUILD_PREFIX}/bin/python3.11

    # make zlib available (todo check if this makes sense in the conda context)
    # embuilder build zlib



    # CONFIG_SITE=../../conda.config.site-wasm32-emscripten  \
    # CONFIG_SITE=../../Tools/wasm/config.site-wasm32-emscripten \
    CONFIG_SITE=../../conda.config.site-wasm32-emscripten READELF=true \
    emconfigure ../../configure -C \
        CFLAGS="-fPIC -O2" \
        --host=wasm32-unknown-emscripten \
        --enable-optimizations \
        --without-pymalloc \
        --disable-shared \
        --disable-ipv6 \
        --build=$(../../config.guess) \
        --with-emscripten-target=browser \
        --with-build-python=python3.11 \
        --prefix=${PREFIX}

        # CPPFLAGS=${CPPFLAGS}\
        # LDFLAGS=${LDFLAGS}\
        # --enable-optimizations \
        
    # build dir is the current dir
    # cp ${RECIPE_DIR}/from_pyodide/Setup.local Modules/
    # cat ${RECIPE_DIR}/from_pyodide/pyconfig.undefs.h >> pyconfig.h

    sed -i -e 's/libinstall:.*/libinstall:/' Makefile; 

    make CROSS_COMPILE=yes  -j$(nproc) || true
    make CROSS_COMPILE=yes  install || true
    # make CROSS_COMPILE=yes -j$(nproc) || true
    # make CROSS_COMPILE=yes install

    mkdir -p $PREFIX/bin/
    mkdir -p $PREFIX/lib/python_internal
    cp -t $PREFIX/bin/ python.* 
    cp -t $PREFIX/lib/python_internal Modules/_decimal/libmpdec/libmpdec.a
    cp -t $PREFIX/lib/python_internal Modules/expat/libexpat.a


    popd

else
    mkdir -p build
    pushd build
    ../configure -C \
        --prefix=$PREFIX

    make -j$(nproc)
    make install
    popd

fi

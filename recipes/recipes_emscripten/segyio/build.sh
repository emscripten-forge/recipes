#!/bin/bash

mkdir build
cd build


# copy includes of python from host to build dir
mkdir -p $BUILD_PREFIX/include/
cp -r $PREFIX/include/python3.13/ $BUILD_PREFIX/include/

emcmake cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DHAVE_FSTATI64=0 -DCMAKE_POSITION_INDEPENDENT_CODE=ON
emmake make
emmake make install

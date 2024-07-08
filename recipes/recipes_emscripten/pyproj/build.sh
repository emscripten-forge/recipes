#!/bin/bash

rm $BUILD_PREFIX/lib/libproj.so
cp $PREFIX/lib/libproj.a $BUILD_PREFIX/lib/

${PYTHON} -m pip install -vv .

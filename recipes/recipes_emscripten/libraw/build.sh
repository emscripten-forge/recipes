#!/bin/bash

cd libraw

autoreconf --install

./configure --prefix="${PREFIX}" --enable-openmp=no

make -j${CPU_COUNT}
make install
#!/bin/bash

mkdir build
cd build

cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DHAVE_FSTATI64=0 -DCMAKE_POSITION_INDEPENDENT_CODE=ON
emmake make
emmake make install
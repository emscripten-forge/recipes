#!/bin/bash

emconfigure ./configure \
   CFLAGS="-fPIC" \
   --prefix=$PREFIX \
   --disable-dependency-tracking \
   --disable-shared
emmake make -j ${CPU_COUNT:-3} install

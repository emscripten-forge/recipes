#!/bin/bash

CFLAGS="-fPIC" emcmake cmake -DCMAKE_INSTALL_PREFIX=$PREFIX .
emmake make -j ${CPU_COUNT:-3}
emmake make install


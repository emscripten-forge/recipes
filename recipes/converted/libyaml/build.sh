#!/bin/bash

CFLAGS="-fPIC" emcmake cmake -DCMAKE_INSTALL_PREFIX=${PREFIX}
emmake make -j ${CPU_COUNT:-3} install
# ln -s libyaml-0.2.1/libyaml_static.a ../libyaml.a
# ln -s libyaml-0.2.1/include ..

#!/bin/bash

CFLAGS="-fPIC" emcmake cmake -DCMAKE_INSTALL_PREFIX=$PREFIX -DCMAKE_POLICY_VERSION_MINIMUM=3.5 .
emmake make -j ${CPU_COUNT:-3}
emmake make install


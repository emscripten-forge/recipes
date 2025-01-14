#!/bin/bash

CFLAGS="-fPIC" emconfigure ./configure  --prefix=$PREFIX --host ""
emmake make -j ${CPU_COUNT:-3} install

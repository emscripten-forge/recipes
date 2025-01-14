#!/bin/bash

CFLAGS="-fPIC" emconfigure ./configure  --prefix=$PREFIX --host unix
emmake make -j ${CPU_COUNT:-3} install

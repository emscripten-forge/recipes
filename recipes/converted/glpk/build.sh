#!/bin/bash

CFLAGS="-fPIC" emconfigure ./configure  --prefix=$PREFIX
emmake make -j ${CPU_COUNT:-3} install
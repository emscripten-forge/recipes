#!/bin/bash

emconfigure ./configure --prefix="${PREFIX}" --disable-shared
make
make install
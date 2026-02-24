#!/bin/bash

export IGRAPH_USE_PKG_CONFIG=1
export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH

${PYTHON} -m pip install . -vvv

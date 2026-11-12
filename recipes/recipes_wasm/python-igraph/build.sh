#!/bin/bash
set -ex

# link against the igraph-static package instead of the vendored C core
export IGRAPH_USE_PKG_CONFIG=1
export IGRAPH_STATIC_EXTENSION=1
# igraph.pc has no Libs.private, so name igraph-static's own static deps
# (setup.py swaps them for the .a files on the library path)
export IGRAPH_EXTRA_LIBRARIES=glpk,gmp,xml2,z
export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig:${PKG_CONFIG_PATH:-}

${PYTHON} -m pip install . -vvv

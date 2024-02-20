#!/bin/bash

RUBY_PACKED=$RECIPE_DIR/ruby-3.2-wasm32-unknown-emscripten-full.tar.gz

tar -xzf $RUBY_PACKED
RUBY_SOURCE_DIR=./ruby-3.2-wasm32-unknown-emscripten-full/user/local

# Copy files to the right place
cp -r ${RUBY_SOURCE_DIR}/bin $PREFIX/bin
cp -r ${RUBY_SOURCE_DIR}/lib $PREFIX/lib
cp -r ${RUBY_SOURCE_DIR}/include $PREFIX/include
cp -r ${RUBY_SOURCE_DIR}/share $PREFIX/share

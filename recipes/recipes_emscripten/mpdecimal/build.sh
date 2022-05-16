#!/usr/bin/env bash


if [[ $target_platform == "emscripten-32" ]]; then
    emconfigure ./configure --prefix="${PREFIX}"
    make 
    make install
fi
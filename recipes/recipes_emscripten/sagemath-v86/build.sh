#!/bin/bash
set -ex

cp -a "${PREFIX}/lib/v86/bios" v86/
cp -a "${PREFIX}/lib/v86/build" v86/ 

cd v86/tools/docker/sagemath
./build.sh
./build-state.js
./compress-split-state.sh

cd ../../../../
rm -f v86/images/debian-9p-rootfs.tar
rm -f v86/images/debian-state-base.bin

rm -rf v86/tools

mkdir -p "$PREFIX/share/sagemath-v86"
cp -a v86/* "$PREFIX/share/sagemath-v86/"
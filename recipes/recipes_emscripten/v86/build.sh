#!/bin/bash
set -ex

# Hide the host system's rustup by filtering .cargo/bin out of the PATH
export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "\.cargo/bin" | grep -v "\.rustup" | tr '\n' ':' | sed 's/:$//')
# Patch the Makefile to pass compatibility flags to the newer LLVM linker
sed -i 's/--global-base=4096/--global-base=4096 --no-stack-first --import-undefined/g' Makefile

make all

mkdir -p ${PREFIX}/lib/v86/build

cp build/v86_all.js ${PREFIX}/lib/v86/build/
cp build/libv86.js ${PREFIX}/lib/v86/build/
cp build/libv86.mjs ${PREFIX}/lib/v86/build/
cp build/v86.wasm ${PREFIX}/lib/v86/build/

cp index.html ${PREFIX}/lib/v86/
cp v86.css ${PREFIX}/lib/v86/
cp -r bios ${PREFIX}/lib/v86/bios
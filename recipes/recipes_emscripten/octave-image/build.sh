#!/usr/bin/env bash
set -euxo pipefail

PKG=image
VER=2.18.1

# The source is already unpacked into ./image by rattler
# Create a tarball exactly like Octave expects
tar -czf ${PKG}-${VER}.tar.gz ${PKG}

# Install using Octave's package manager
octave -W -H --eval "pkg install -global -verbose ${PKG}-${VER}.tar.gz || cat config.log"

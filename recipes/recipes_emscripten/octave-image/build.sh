#!/usr/bin/env bash
set -euxo pipefail

log() {
  echo
  echo "==== $* ===="
}

PKG=image
VER=2.18.1

log "Build environment"
echo "PWD            = $(pwd)"
echo "PREFIX         = ${PREFIX:-<unset>}"
echo "BUILD_PREFIX   = ${BUILD_PREFIX:-<unset>}"
echo "PATH           = $PATH"
which octave || true
which mkoctfile || true
which g++ || true
octave --version || true

log "Source tree sanity check"
ls -lah .
ls -lah "${PKG}"
ls -lah "${PKG}/src" || true
ls -lah "${PKG}/inst" || true

log "Creating Octave package tarball"
tar -czf "${PKG}-${VER}.tar.gz" "${PKG}"
ls -lah "${PKG}-${VER}.tar.gz"

log "Running pkg install (this WILL run configure)"
octave -W -H --eval "
  disp('Octave version:');
  disp(version);
  disp('mkoctfile path:');
  system('which mkoctfile');
  disp('Compiler info:');
  system('mkoctfile -p CXX');
  disp('Starting pkg install...');
  pkg install -global -verbose ${PKG}-${VER}.tar.gz;
"

log "pkg install completed"

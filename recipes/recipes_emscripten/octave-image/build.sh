#!/usr/bin/env bash
set -euxo pipefail

PKG=image
VER=2.18.1
BUILD_DIR="_builddir"

LOG_DIR="${SRC_DIR:-$PWD}/config-logs"
mkdir -p "${LOG_DIR}"

# Create tarball exactly how Octave expects
tar -czf ${PKG}-${VER}.tar.gz ${PKG}

# Run build only (no install)
octave -W -H --eval "pkg build ${BUILD_DIR} ${PKG}-${VER}.tar.gz -verbose" || true

CONFIG_LOG="${BUILD_DIR}/${PKG}/src/config.log"

if [[ -f "${CONFIG_LOG}" ]]; then
  echo "===== config.log ====="
  cat "${CONFIG_LOG}"
  echo "===== end config.log ====="

  cp "${CONFIG_LOG}" "${LOG_DIR}/config.log"
else
  echo "config.log not found at ${CONFIG_LOG}"
  echo "Build directory contents:"
  find "${BUILD_DIR}" -maxdepth 4 || true
  exit 1
fi

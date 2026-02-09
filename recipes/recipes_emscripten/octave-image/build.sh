#!/usr/bin/env bash
set -euxo pipefail

PKG=image
VER=2.18.1

OCT_PKG_DIR="$PREFIX/share/octave/packages/${PKG}-${VER}"

echo "Installing Octave package to:"
echo "  ${OCT_PKG_DIR}"

mkdir -p "${OCT_PKG_DIR}"

# Required metadata
cp "${PKG}/DESCRIPTION" "${OCT_PKG_DIR}/"

# Optional hooks
[ -f "${PKG}/PKG_ADD" ] && cp "${PKG}/PKG_ADD" "${OCT_PKG_DIR}/"
[ -f "${PKG}/PKG_DEL" ] && cp "${PKG}/PKG_DEL" "${OCT_PKG_DIR}/"

# Install functions
cp -r "${PKG}/inst" "${OCT_PKG_DIR}/"

# Optional documentation
[ -d "${PKG}/doc" ] && cp -r "${PKG}/doc" "${OCT_PKG_DIR}/"

echo "Package files installed."

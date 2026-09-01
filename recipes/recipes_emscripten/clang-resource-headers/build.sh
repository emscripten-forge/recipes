#!/bin/bash
set -euxo pipefail

RESOURCE_DIR="${PREFIX}/lib/clang/${PKG_VERSION%%.*}/include"
mkdir -p "${RESOURCE_DIR}"
cp -R "${SRC_DIR}/clang/lib/Headers/." "${RESOURCE_DIR}/"

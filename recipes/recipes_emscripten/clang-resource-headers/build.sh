#!/bin/bash
set -euxo pipefail

RESOURCE_DIR="${PREFIX}/lib/clang/22/include"
mkdir -p "${RESOURCE_DIR}"
cp -R "${SRC_DIR}/clang/lib/Headers/." "${RESOURCE_DIR}/"

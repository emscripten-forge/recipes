#!/usr/bin/env bash
set -euo pipefail

echo "Checking Qt6 image-format plugin CMake configs are installed"
for cfg in \
    "${PREFIX}/lib/cmake/Qt6Gui/Qt6QTiffPluginConfig.cmake" \
    "${PREFIX}/lib/cmake/Qt6Gui/Qt6QWebpPluginConfig.cmake"; do
    test -f "${cfg}" || { echo "missing: ${cfg}"; exit 1; }
done
echo "Qt6 imageformats plugin configs OK"

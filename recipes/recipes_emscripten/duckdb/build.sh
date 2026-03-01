#!/bin/bash
set -euo pipefail

# DuckDB-specific CMake flags for wasm passed via scikit-build-core config settings
${PYTHON} -m pip install . ${PIP_ARGS} \
  -Ccmake.define.OVERRIDE_GIT_DESCRIBE="v${PKG_VERSION}" \
  -Ccmake.define.CMAKE_INSTALL_LIBDIR=lib \
  -Ccmake.define.BUILD_EXTENSIONS="parquet;json;autocomplete" \
  -Ccmake.define.BUILD_SHELL=OFF \
  -Ccmake.define.BUILD_UNITTESTS=OFF \
  -Ccmake.define.ENABLE_EXTENSION_AUTOLOADING=OFF \
  -Ccmake.define.ENABLE_EXTENSION_AUTOINSTALL=OFF

# duckdb's CMake install falls back to CMAKE_INSTALL_LIBDIR when
# SKBUILD_PLATLIB_DIR is not detected, placing _duckdb.so in a lib/
# subdirectory. Move it to the correct location.
SITE_PACKAGES=$(${PYTHON} -c "import sysconfig; print(sysconfig.get_path('platlib'))")
if [ -f "${SITE_PACKAGES}/lib/_duckdb.so" ]; then
  mv "${SITE_PACKAGES}/lib/_duckdb.so" "${SITE_PACKAGES}/_duckdb.so"
  rmdir "${SITE_PACKAGES}/lib" 2>/dev/null || true
fi

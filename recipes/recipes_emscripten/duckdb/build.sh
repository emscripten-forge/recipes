#!/bin/bash
set -euo pipefail

# Setup emscripten toolchain for scikit-build-core
emscripten_root=$(em-config EMSCRIPTEN_ROOT)
toolchain_path="${emscripten_root}/cmake/Modules/Platform/Emscripten.cmake"

export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_TOOLCHAIN_FILE=${toolchain_path} -DCMAKE_PROJECT_INCLUDE=${RECIPE_DIR}/overwriteProp.cmake"

# DuckDB-specific CMake flags for wasm passed via scikit-build-core config settings
${PYTHON} -m pip install . ${PIP_ARGS} \
  -Ccmake.define.OVERRIDE_GIT_DESCRIBE="v${PKG_VERSION}" \
  -Ccmake.define.BUILD_EXTENSIONS="parquet;json;autocomplete" \
  -Ccmake.define.BUILD_SHELL=OFF \
  -Ccmake.define.BUILD_UNITTESTS=OFF \
  -Ccmake.define.ENABLE_EXTENSION_AUTOLOADING=OFF \
  -Ccmake.define.ENABLE_EXTENSION_AUTOINSTALL=OFF \
  -Ccmake.define.CMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF

#!/bin/bash

set -euxo pipefail

# Clad's standalone CMake finds LLVM and then Clang.
# In emscripten-forge, ClangConfig.cmake references LLD imported targets
# such as lldWasm and lldCommon, so load LLD before Clang.
python - <<'PY'
import os
from pathlib import Path

p = Path(os.environ["SRC_DIR"]) / "CMakeLists.txt"
txt = p.read_text()

needle = "  ## Find supported Clang"
insert = r'''
  ## Find LLD before Clang because this LLVM/Clang package exports
  ## Clang targets that reference lldWasm and lldCommon.
  if (DEFINED LLD_DIR)
    find_package(LLD REQUIRED CONFIG
      PATHS ${LLD_DIR} "${LLD_DIR}/lib/cmake/lld" "${LLD_DIR}/cmake"
      NO_DEFAULT_PATH)
  else()
    find_package(LLD REQUIRED CONFIG)
  endif()

'''

if insert not in txt:
    if needle not in txt:
        raise RuntimeError("Could not find insertion point for LLD find_package patch")
    txt = txt.replace(needle, insert + needle)

p.write_text(txt)
PY

mkdir build
cd build

export CMAKE_PREFIX_PATH="$PREFIX"
export CMAKE_SYSTEM_PREFIX_PATH="$PREFIX"

# Match the cppinterop recipe style. These emscripten-forge defaults can
# sometimes inject flags that are not friendly to LLVM/Clang CMake projects.
# unset EM_FORGE_OPTFLAGS
# unset EM_FORGE_DBGFLAGS
# unset EM_FORGE_LDFLAGS_BASE
# unset EM_FORGE_CFLAGS_BASE
# unset EM_FORGE_SIDE_MODULE_LDFLAGS
# unset EM_FORGE_SIDE_MODULE_CFLAGS

# unset CFLAGS
# unset CXXFLAGS
# unset LDFLAGS

emcmake cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="$PREFIX" \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_PROJECT_INCLUDE=${RECIPE_DIR}/overwriteProp.cmake \
    -DLLVM_DIR="$PREFIX/lib/cmake/llvm" \
    -DLLD_DIR="$PREFIX/lib/cmake/lld" \
    -DClang_DIR="$PREFIX/lib/cmake/clang" \
    -DLLVM_EXTERNAL_LIT="$(which lit || true)" \
    -DBUILD_SHARED_LIBS=ON \
    -DCLAD_DISABLE_TESTS=ON \
    -DCLAD_ENABLE_BENCHMARKS=OFF \
    -DCLAD_INCLUDE_DOCS=OFF \
    -DCLAD_ENABLE_DOXYGEN=OFF \
    -DCLAD_ENABLE_SPHINX=OFF \
    -DCLAD_ENABLE_ENZYME_BACKEND=OFF \
    "$SRC_DIR"

emmake make -j1
emmake make install

#!/bin/bash
set -euo pipefail

export CFLAGS="${CFLAGS:-} ${EM_FORGE_SIDE_MODULE_CFLAGS:-}"
export CXXFLAGS="${CXXFLAGS:-} ${EM_FORGE_SIDE_MODULE_CFLAGS:-}"
export LDFLAGS="${LDFLAGS:-} ${EM_FORGE_SIDE_MODULE_LDFLAGS:-}"

src_dir="$(dirname "$PWD")/executorch"
ln -sfn "$PWD" "$src_dir"
export PYTHONPATH="$(dirname "$src_dir"):${PYTHONPATH:-}"
host_cc="$(command -v clang || command -v cc)"
host_cxx="$(command -v clang++ || command -v c++)"
host_node="${BUILD_PREFIX}/bin/node"

if [ ! -x "${host_node}" ]; then
    host_node="$(command -v node)"
fi

rm -rf third-party/flatbuffers
mkdir -p third-party/flatbuffers
ln -sfn "${PREFIX}/include" third-party/flatbuffers/include

rm -rf third-party/gflags
mkdir -p third-party/gflags
cat <<'EOF' > third-party/gflags/CMakeLists.txt
find_package(gflags CONFIG REQUIRED)
if(TARGET gflags AND NOT TARGET gflags::gflags)
    add_library(gflags::gflags ALIAS gflags)
endif()
EOF

rm -rf backends/xnnpack/third-party/FXdiv
mkdir -p backends/xnnpack/third-party/FXdiv
ln -sfn "${PREFIX}/include" backends/xnnpack/third-party/FXdiv/include
cat <<'EOF' > backends/xnnpack/third-party/FXdiv/CMakeLists.txt
add_library(fxdiv INTERFACE)
target_include_directories(fxdiv INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/include)
add_library(FXdiv ALIAS fxdiv)
EOF

rm -rf third-party/flatcc
mkdir -p third-party/flatcc

EXECUTORCH_SRC_DIR="$src_dir" EXECUTORCH_HOST_CC="$host_cc" EXECUTORCH_HOST_CXX="$host_cxx" EXECUTORCH_HOST_FLATC="${BUILD_PREFIX}/bin/flatc" EXECUTORCH_HOST_NODE="$host_node" EXECUTORCH_PREFIX="${PREFIX}" python <<'PY'
from pathlib import Path
import os

path = Path(os.environ["EXECUTORCH_SRC_DIR"]) / "third-party" / "CMakeLists.txt"
text = path.read_text()
host_cc = os.environ["EXECUTORCH_HOST_CC"]
host_cxx = os.environ["EXECUTORCH_HOST_CXX"]
host_flatc = os.environ["EXECUTORCH_HOST_FLATC"]
host_node = os.environ["EXECUTORCH_HOST_NODE"]
prefix = os.environ["EXECUTORCH_PREFIX"]
flatcc_js = f"{prefix}/bin/flatcc.js"
flatcc_wasm = f"{prefix}/bin/flatcc.wasm"
flatcc_rt = f"{prefix}/lib/libflatccrt.a"

replacements = [
    (
        "add_subdirectory(json)\n",
        "find_package(nlohmann_json CONFIG REQUIRED)\n",
    ),
    (
        "if(NOT ${CMAKE_SYSTEM_PROCESSOR} MATCHES Hexagon)\n  add_subdirectory(gflags)\nendif()\n\n",
        "if(NOT ${CMAKE_SYSTEM_PROCESSOR} MATCHES Hexagon)\n  find_package(gflags CONFIG REQUIRED)\nendif()\n\n",
    ),
    (
        "if(BUILD_TESTING)\n  add_subdirectory(googletest)\nendif()\n\n# MARK: - flatbuffers\n",
        f"if(BUILD_TESTING)\n  add_subdirectory(googletest)\nendif()\n\nset(_executorch_host_c_compiler {host_cc})\nset(_executorch_host_cxx_compiler {host_cxx})\nset(\n  _executorch_host_env\n  ${{CMAKE_COMMAND}}\n  -E\n  env\n  --unset=CC\n  --unset=CXX\n  --unset=AR\n  --unset=RANLIB\n  --unset=CFLAGS\n  --unset=CXXFLAGS\n  --unset=CPPFLAGS\n  --unset=LDFLAGS)\n\n# MARK: - flatbuffers\n",
    ),
    (
        "if(WIN32)\n  set(_executorch_external_project_additional_args)\nelse()\n  # Always use Make to avoid needing to codesign flatc if the project is using Xcode.\n  set(_executorch_external_project_additional_args CMAKE_GENERATOR \"Unix Makefiles\")\nendif()\n",
        "if(WIN32)\n  set(_executorch_host_generator_args)\nelse()\n  # Always use Make to avoid needing to codesign flatc if the project is using Xcode.\n  set(_executorch_host_generator_args -G \"Unix Makefiles\")\nendif()\n",
    ),
    (
        "ExternalProject_Add(\n  flatbuffers_ep\n  PREFIX ${CMAKE_CURRENT_BINARY_DIR}/flatc_ep\n  BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/flatc_ep/src/build\n  SOURCE_DIR ${PROJECT_SOURCE_DIR}/third-party/flatbuffers\n  CMAKE_ARGS -DFLATBUFFERS_BUILD_FLATC=ON\n             -DFLATBUFFERS_INSTALL=ON\n             -DFLATBUFFERS_BUILD_FLATHASH=OFF\n             -DFLATBUFFERS_BUILD_FLATLIB=OFF\n             -DFLATBUFFERS_BUILD_TESTS=OFF\n             -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR>\n             -DCMAKE_CXX_FLAGS=\"-DFLATBUFFERS_MAX_ALIGNMENT=${EXECUTORCH_FLATBUFFERS_MAX_ALIGNMENT}\"\n             # Unset the toolchain to build for the host instead of the toolchain set for the project.\n             -DCMAKE_TOOLCHAIN_FILE=\n             # If building for iOS, \"unset\" these variables to rely on the host (macOS) defaults.\n             $<$<AND:$<BOOL:${APPLE}>,$<BOOL:$<FILTER:${PLATFORM},EXCLUDE,^MAC>>>:-DCMAKE_OSX_SYSROOT=>\n             -DCMAKE_OSX_DEPLOYMENT_TARGET:STRING=${CMAKE_OSX_DEPLOYMENT_TARGET}\n  BUILD_BYPRODUCTS <INSTALL_DIR>/bin/flatc\n  ${_executorch_external_project_additional_args}\n)\nExternalProject_Get_Property(flatbuffers_ep INSTALL_DIR)\nadd_executable(flatc IMPORTED GLOBAL)\nadd_dependencies(flatc flatbuffers_ep)\nif(WIN32 AND NOT CMAKE_CROSSCOMPILING)\n  # flatbuffers does not use CMAKE_BUILD_TYPE. Internally, the build forces Release\n  # config, but from CMake's perspective the build type is always Debug.\n  set_target_properties(flatc PROPERTIES IMPORTED_LOCATION ${INSTALL_DIR}/bin/flatc.exe)\nelse()\n  set_target_properties(flatc PROPERTIES IMPORTED_LOCATION ${INSTALL_DIR}/bin/flatc)\nendif()\n",
        f"if(NOT EXISTS \"{host_flatc}\")\n  message(FATAL_ERROR \"Expected host flatc at {host_flatc}\")\nendif()\nadd_executable(flatc IMPORTED GLOBAL)\nset_target_properties(flatc PROPERTIES IMPORTED_LOCATION \"{host_flatc}\")\n",
    ),
    (
        "ExternalProject_Add(\n  flatcc_ep\n  PREFIX ${CMAKE_CURRENT_BINARY_DIR}/flatcc_ep\n  SOURCE_DIR ${PROJECT_SOURCE_DIR}/third-party/flatcc\n  BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/flatcc_ep/src/build\n  CMAKE_ARGS -DFLATCC_RTONLY=OFF\n             -DFLATCC_TEST=OFF\n             -DFLATCC_REFLECTION=OFF\n             -DFLATCC_DEBUG_CLANG_SANITIZE=OFF\n             -DFLATCC_INSTALL=ON\n             -DCMAKE_POLICY_VERSION_MINIMUM=3.5\n             -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR>\n             -DCMAKE_POSITION_INDEPENDENT_CODE=ON\n             -DCMAKE_TOOLCHAIN_FILE=\n             $<$<AND:$<BOOL:${APPLE}>,$<BOOL:$<FILTER:${PLATFORM},EXCLUDE,^MAC>>>:-DCMAKE_OSX_SYSROOT=>\n             -DCMAKE_OSX_DEPLOYMENT_TARGET:STRING=${CMAKE_OSX_DEPLOYMENT_TARGET}\n             ${_flatcc_extra_cmake_args}\n  BUILD_BYPRODUCTS <INSTALL_DIR>/bin/flatcc\n  {_executorch_external_project_additional_args}\n)\nfile(REMOVE_RECURSE ${PROJECT_SOURCE_DIR}/third-party/flatcc/lib)\nExternalProject_Get_Property(flatcc_ep INSTALL_DIR)\nadd_executable(flatcc_cli IMPORTED GLOBAL)\nadd_dependencies(flatcc_cli flatcc_ep)\nif(WIN32 AND NOT CMAKE_CROSSCOMPILING)\n  set_target_properties(flatcc_cli PROPERTIES IMPORTED_LOCATION ${INSTALL_DIR}/bin/flatcc.exe)\nelse()\n  set_target_properties(flatcc_cli PROPERTIES IMPORTED_LOCATION ${INSTALL_DIR}/bin/flatcc)\nendif()\n\nset(FLATCC_RTONLY ON CACHE BOOL \"\")\nset(FLATCC_TEST OFF CACHE BOOL \"\")\nset(FLATCC_REFLECTION OFF CACHE BOOL \"\")\nset(FLATCC_DEBUG_CLANG_SANITIZE OFF CACHE BOOL \"\")\nset(FLATCC_INSTALL OFF CACHE BOOL \"\")\nadd_subdirectory(flatcc)\n# Unfortunately flatcc writes libs directly in to the source tree [1]. So to\n# ensure the target lib is created last, force flatcc_cli to build first.\n#\n# [1] https://github.com/dvidelabs/flatcc/blob/896db54787e8b730a6be482c69324751f3f5f117/CMakeLists.txt#L168\nadd_dependencies(flatccrt flatcc_cli)\n# Fix for \"relocation R_X86_64_32 against `.rodata' can not be used when making\n# a shared object; recompile with -fPIC\" when building on some x86 linux\n# systems.\n#\n# Learn more: https://github.com/pytorch/executorch/pull/2467\nset_property(TARGET flatccrt PROPERTY POSITION_INDEPENDENT_CODE ON)\ninstall(\n  TARGETS flatccrt\n  DESTINATION ${CMAKE_BINARY_DIR}/lib\n)\n",
        f"if(NOT EXISTS \"{flatcc_js}\")\n  message(FATAL_ERROR \"Expected packaged flatcc at {flatcc_js}\")\nendif()\nif(NOT EXISTS \"{flatcc_wasm}\")\n  message(FATAL_ERROR \"Expected packaged flatcc wasm sidecar at {flatcc_wasm}\")\nendif()\nif(NOT EXISTS \"{flatcc_rt}\")\n  message(FATAL_ERROR \"Expected packaged flatccrt at {flatcc_rt}\")\nendif()\nset(_executorch_flatcc_cli \"${{CMAKE_CURRENT_BINARY_DIR}}/flatcc\")\nfile(WRITE \"${{_executorch_flatcc_cli}}\" \"#!/bin/sh\\nexec {host_node} {flatcc_js} \\\"$@\\\"\\n\")\nexecute_process(COMMAND ${{CMAKE_COMMAND}} -E chmod +x \"${{_executorch_flatcc_cli}}\")\nadd_executable(flatcc_cli IMPORTED GLOBAL)\nset_target_properties(flatcc_cli PROPERTIES IMPORTED_LOCATION \"${{_executorch_flatcc_cli}}\")\nadd_library(flatccrt STATIC IMPORTED GLOBAL)\nset_target_properties(flatccrt PROPERTIES IMPORTED_LOCATION \"{flatcc_rt}\" INTERFACE_INCLUDE_DIRECTORIES \"{prefix}/include\")\nfile(MAKE_DIRECTORY \"${{CMAKE_BINARY_DIR}}/lib\")\nconfigure_file(\"{flatcc_rt}\" \"${{CMAKE_BINARY_DIR}}/lib/libflatccrt.a\" COPYONLY)\n",
    ),
]

for old, new in replacements:
    if old not in text:
        raise SystemExit(f"expected snippet not found in {path}: {old.splitlines()[0]}")
    text = text.replace(old, new, 1)

path.write_text(text)
PY

emcmake cmake -S "$src_dir" -B build \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -Dgflags_DIR="${PREFIX}/lib/cmake/gflags" \
    -Dnlohmann_json_DIR="${PREFIX}/share/cmake/nlohmann_json" \
    -DBUILD_TESTING=OFF \
    -DEXECUTORCH_BUILD_TESTS=OFF \
    -DEXECUTORCH_BUILD_DEVTOOLS=OFF \
    -DEXECUTORCH_BUILD_EXECUTOR_RUNNER=OFF \
    -DEXECUTORCH_BUILD_EXTENSION_DATA_LOADER=ON \
    -DEXECUTORCH_BUILD_EXTENSION_FLAT_TENSOR=ON \
    -DEXECUTORCH_BUILD_EXTENSION_MODULE=ON \
    -DEXECUTORCH_BUILD_EXTENSION_NAMED_DATA_MAP=ON \
    -DEXECUTORCH_BUILD_EXTENSION_TENSOR=ON \
    -DEXECUTORCH_BUILD_CPUINFO=OFF \
    -DEXECUTORCH_BUILD_PTHREADPOOL=OFF \
    -DEXECUTORCH_BUILD_WASM=ON \
    -DEXECUTORCH_BUILD_XNNPACK=OFF

emmake ninja -C build -j"${CPU_COUNT}"
emmake ninja -C build install

if [ -f build/lib/libextension_evalue_util.a ]; then
    install -Dm644 build/lib/libextension_evalue_util.a "${PREFIX}/lib/libextension_evalue_util.a"
    sed -i "s|\"$PWD/build/lib/libextension_evalue_util.a\"|\"\${_IMPORT_PREFIX}/lib/libextension_evalue_util.a\"|g" \
        "${PREFIX}/lib/cmake/ExecuTorch/ExecuTorchTargets-release.cmake"
fi
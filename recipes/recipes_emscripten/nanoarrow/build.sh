#!/bin/bash
set -euo pipefail

export CFLAGS="${CFLAGS:-} ${EM_FORGE_SIDE_MODULE_CFLAGS:-}"
export CXXFLAGS="${CXXFLAGS:-} ${EM_FORGE_SIDE_MODULE_CFLAGS:-}"
export LDFLAGS="${LDFLAGS:-} ${EM_FORGE_SIDE_MODULE_LDFLAGS:-}"

emcmake cmake -S . -B build \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DLZ4_INCLUDE_DIRS="${PREFIX}/include" \
    -DLZ4_LIBRARY_DIRS="${PREFIX}/lib" \
    -DLZ4_LIBRARIES="${PREFIX}/lib/liblz4.a" \
    -Dzstd_DIR="${PREFIX}/lib/cmake/zstd" \
    -Dzstd_ROOT="${PREFIX}" \
    -DZSTD_ROOT="${PREFIX}" \
    -DZSTD_LIB="${PREFIX}/lib/libzstd.a" \
    -DZSTD_INCLUDE_DIR="${PREFIX}/include" \
    -DBUILD_SHARED_LIBS=OFF \
    -DNANOARROW_INSTALL_SHARED=OFF \
    -DNANOARROW_IPC=ON \
    -DNANOARROW_IPC_WITH_LZ4=ON \
    -DNANOARROW_IPC_WITH_ZSTD=ON \
    -DNANOARROW_INSTALL_SHARED=OFF \
    -DNANOARROW_DEVICE=OFF \
    -DNANOARROW_TESTING=OFF \
    -DNANOARROW_BUILD_APPS=OFF \
    -DNANOARROW_BUILD_TESTS=OFF \
    -DNANOARROW_BUILD_TESTS_WITH_ARROW=OFF \
    -DNANOARROW_BUILD_BENCHMARKS=OFF \
    -DNANOARROW_BUILD_INTEGRATION_TESTS=OFF

emmake ninja -C build
emmake ninja -C build install

rm -f "${PREFIX}/lib/libnanoarrow_shared.a" \
    "${PREFIX}/lib/libnanoarrow_ipc_shared.a"

perl -0pi -e 's/ nanoarrow::nanoarrow_shared//g; s/ nanoarrow::nanoarrow_ipc_shared//g; s@\n# Create imported target nanoarrow::nanoarrow_shared\nadd_library\(nanoarrow::nanoarrow_shared STATIC IMPORTED\)\n\nset_target_properties\(nanoarrow::nanoarrow_shared PROPERTIES\n  INTERFACE_COMPILE_DEFINITIONS "\\\$<\\\$<CONFIG:Debug>:NANOARROW_DEBUG>"\n  INTERFACE_INCLUDE_DIRECTORIES "\$\{_IMPORT_PREFIX\}/include"\n\)\n@@s; s@\n# Create imported target nanoarrow::nanoarrow_ipc_shared\nadd_library\(nanoarrow::nanoarrow_ipc_shared STATIC IMPORTED\)\n\nset_target_properties\(nanoarrow::nanoarrow_ipc_shared PROPERTIES\n  INTERFACE_COMPILE_DEFINITIONS "\\\$<\\\$<CONFIG:Debug>:NANOARROW_DEBUG>"\n  INTERFACE_INCLUDE_DIRECTORIES "\$\{_IMPORT_PREFIX\}/include"\n  INTERFACE_LINK_LIBRARIES "\\\$<LINK_ONLY:nanoarrow::flatccrt>;\\\$<LINK_ONLY:zstd::libzstd_static>;\\\$<LINK_ONLY:lz4::lz4>;nanoarrow::nanoarrow_shared;nanoarrow::nanoarrow_coverage_config"\n\)\n@@s' "${PREFIX}/lib/cmake/nanoarrow/nanoarrow-targets.cmake"

perl -0pi -e 's@\n# Import target "nanoarrow::nanoarrow_shared" for configuration "Release"\nset_property\(TARGET nanoarrow::nanoarrow_shared APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE\)\nset_target_properties\(nanoarrow::nanoarrow_shared PROPERTIES\n  IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE "C"\n  IMPORTED_LOCATION_RELEASE "\$\{_IMPORT_PREFIX\}/lib/libnanoarrow_shared.a"\n  \)\n\nlist\(APPEND _cmake_import_check_targets nanoarrow::nanoarrow_shared \)\nlist\(APPEND _cmake_import_check_files_for_nanoarrow::nanoarrow_shared "\$\{_IMPORT_PREFIX\}/lib/libnanoarrow_shared.a" \)\n@@s; s@\n# Import target "nanoarrow::nanoarrow_ipc_shared" for configuration "Release"\nset_property\(TARGET nanoarrow::nanoarrow_ipc_shared APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE\)\nset_target_properties\(nanoarrow::nanoarrow_ipc_shared PROPERTIES\n  IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE "C"\n  IMPORTED_LOCATION_RELEASE "\$\{_IMPORT_PREFIX\}/lib/libnanoarrow_ipc_shared.a"\n  \)\n\nlist\(APPEND _cmake_import_check_targets nanoarrow::nanoarrow_ipc_shared \)\nlist\(APPEND _cmake_import_check_files_for_nanoarrow::nanoarrow_ipc_shared "\$\{_IMPORT_PREFIX\}/lib/libnanoarrow_ipc_shared.a" \)\n@@s' "${PREFIX}/lib/cmake/nanoarrow/nanoarrow-targets-release.cmake"
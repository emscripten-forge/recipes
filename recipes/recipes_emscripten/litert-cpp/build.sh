#!/bin/bash
set -euo pipefail

export CFLAGS="${CFLAGS:-} ${EM_FORGE_SIDE_MODULE_CFLAGS:-} -DLITERT_DISABLE_GPU -DLITERT_DISABLE_NPU"

PYINC="$(find "${PREFIX}/include" -maxdepth 1 -name 'python3*' -type d | head -1)"
export CXXFLAGS="${CXXFLAGS:-} ${EM_FORGE_SIDE_MODULE_CFLAGS:-} -I${PYINC} -DLITERT_DISABLE_GPU -DLITERT_DISABLE_NPU"
export LDFLAGS="${LDFLAGS:-} ${EM_FORGE_SIDE_MODULE_LDFLAGS:-}"

# ============================================================================
# Python bindings: ONE merged pybind11 SIDE_MODULE with the static runtime
# embedded (upstream ":emscripten" static configuration). The three upstream
# pybind modules become submodules of a single "_ai_edge_litert" module so
# there is exactly one registries copy per process (no split-brain), and the
# environment's runtime_path option is inert because nothing dlopens in the
# static build. The wrapper is built as a target INSIDE the main cmake tree
# so it reuses its proven dependency machinery (fetched absl, flatbuffers...).
# ============================================================================
WRAP="litert/python/litert_wrapper"

# Rename the three PYBIND11_MODULE(...) definitions into plain init functions
# (the umbrella module below assembles them as submodules).
sed -i 's/PYBIND11_MODULE(_pywrap_litert_compiled_model_wrapper, m)/void init_pywrap_litert_compiled_model_wrapper(py::module_ \&m)/' \
    "${WRAP}/compiled_model_wrapper/compiled_model_wrapper_pybind11.cc"
sed -i 's/PYBIND11_MODULE(_pywrap_litert_environment_wrapper, m)/void init_pywrap_litert_environment_wrapper(py::module_ \&m)/' \
    "${WRAP}/environment_wrapper/environment_wrapper_pybind11.cc"
sed -i 's/PYBIND11_MODULE(_pywrap_litert_tensor_buffer_wrapper, m)/void init_pywrap_litert_tensor_buffer_wrapper(py::module_ \&m)/' \
    "${WRAP}/tensor_buffer_wrapper/tensor_buffer_wrapper_pybind11.cc"

mkdir -p litert/python_wrapper
cat > litert/python_wrapper/umbrella.cc <<'EOF'
#include <pybind11/pybind11.h>
namespace py = pybind11;

void init_pywrap_litert_compiled_model_wrapper(py::module_& m);
void init_pywrap_litert_environment_wrapper(py::module_& m);
void init_pywrap_litert_tensor_buffer_wrapper(py::module_& m);

PYBIND11_MODULE(_ai_edge_litert, m) {
  auto m_cm = m.def_submodule("_pywrap_litert_compiled_model_wrapper");
  init_pywrap_litert_compiled_model_wrapper(m_cm);
  auto m_env = m.def_submodule("_pywrap_litert_environment_wrapper");
  init_pywrap_litert_environment_wrapper(m_env);
  auto m_tb = m.def_submodule("_pywrap_litert_tensor_buffer_wrapper");
  init_pywrap_litert_tensor_buffer_wrapper(m_tb);
}
EOF

# The cmake feature gates (LITERT_ENABLE_GPU/NPU=OFF) exclude the
# accelerator registry sources, but auto_registration.cc references the
# Register* functions unconditionally; provide a matching stub for the GPU
# registry (npu_registry.cc ships its own LITERT_DISABLE_NPU fallback, and
# webnn_registry.cc is always compiled) so the side module's dlopen
# resolution succeeds (the caller ignores the status).
cat > litert/python_wrapper/stub_registries.cc <<'EOF'
#include "litert/c/litert_common.h"
#include "litert/core/environment.h"

namespace litert::internal {

LiteRtStatus RegisterGpuAccelerator(LiteRtEnvironment environment) {
  return kLiteRtStatusErrorUnsupported;
}

}  // namespace litert::internal
EOF

cat > litert/python_wrapper/CMakeLists.txt <<'EOF'
cmake_minimum_required(VERSION 3.20)

if(EMSCRIPTEN)
    set_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS TRUE)
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -s SIDE_MODULE=1")
    set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} -s SIDE_MODULE=1")
    set(CMAKE_STRIP FALSE)
endif()

set(_WRAP_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../python/litert_wrapper)

# conda pybind11 headers (header-only runtime, installed in the BUILD env)
add_library(_pybind11_headers INTERFACE)
target_include_directories(_pybind11_headers INTERFACE $ENV{BUILD_PREFIX}/include $ENV{PREFIX}/include/python3.13)

add_library(_ai_edge_litert SHARED
    umbrella.cc
    stub_registries.cc
    ${_WRAP_DIR}/common/litert_wrapper_utils.cc
    ${_WRAP_DIR}/compiled_model_wrapper/compiled_model_wrapper.cc
    ${_WRAP_DIR}/compiled_model_wrapper/compiled_model_wrapper_pybind11.cc
    ${_WRAP_DIR}/environment_wrapper/environment_wrapper.cc
    ${_WRAP_DIR}/environment_wrapper/environment_wrapper_pybind11.cc
    ${_WRAP_DIR}/tensor_buffer_wrapper/tensor_buffer_wrapper.cc
    ${_WRAP_DIR}/tensor_buffer_wrapper/tensor_buffer_wrapper_pybind11.cc
)

set_target_properties(_ai_edge_litert PROPERTIES
    PREFIX ""
    OUTPUT_NAME _ai_edge_litert
    LINKER_LANGUAGE CXX
)

target_include_directories(_ai_edge_litert PRIVATE
    ${CMAKE_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/../third_party/tensorflow
)

# Explicit, deduplicated archive list in dependency order: litert's PUBLIC
# chains re-export the same archives and wasm-ld rejects duplicated inputs,
# and target-based linking would also leak a -pthread that forces
# --shared-memory (incompatible with the atomics-free pyjs runtime).
target_link_libraries(_ai_edge_litert PRIVATE
    _pybind11_headers
    ${CMAKE_BINARY_DIR}/cc/liblitert_cc_api.a
    ${CMAKE_BINARY_DIR}/cc/internal/liblitert_cc_internal.a
    ${CMAKE_BINARY_DIR}/c/liblitert_c_api.a
    ${CMAKE_BINARY_DIR}/core/liblitert_core.a
    ${CMAKE_BINARY_DIR}/core/model/liblitert_core_model.a
    ${CMAKE_BINARY_DIR}/runtime/liblitert_runtime.a
    ${CMAKE_BINARY_DIR}/tflite_build/libtensorflow-lite.a
    ${CMAKE_BINARY_DIR}/core/cache/liblitert_core_cache.a
    ${CMAKE_BINARY_DIR}/compiler/liblitert_compiler_plugin.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/log/libabsl_die_if_null.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/log/libabsl_log_internal_conditions.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/log/libabsl_log_internal_message.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/debugging/libabsl_examine_stack.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/log/libabsl_log_internal_format.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/log/libabsl_log_internal_nullguard.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/log/libabsl_log_internal_structured_proto.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/log/libabsl_log_internal_log_sink_set.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/log/libabsl_log_internal_globals.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/log/libabsl_log_globals.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/log/libabsl_log_sink.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/log/libabsl_log_entry.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/log/libabsl_log_internal_proto.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/log/libabsl_vlog_config_internal.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/log/libabsl_log_internal_fnmatch.a
    ${CMAKE_BINARY_DIR}/c/liblitert_logging.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/flags/libabsl_flags_internal.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/flags/libabsl_flags_marshalling.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/flags/libabsl_flags_reflection.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/flags/libabsl_flags_config.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/flags/libabsl_flags_program_name.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/flags/libabsl_flags_private_handle_accessor.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/flags/libabsl_flags_commandlineflag.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/flags/libabsl_flags_commandlineflag_internal.a
    ${CMAKE_BINARY_DIR}/_deps/farmhash-build/libfarmhash.a
    ${CMAKE_BINARY_DIR}/_deps/fft2d-build/libfft2d_fftsg2d.a
    ${CMAKE_BINARY_DIR}/_deps/fft2d-build/libfft2d_fftsg.a
    ${CMAKE_BINARY_DIR}/_deps/gemmlowp-build/libeight_bit_int_gemm.a
    ${CMAKE_BINARY_DIR}/_deps/ruy-build/ruy/libruy_context_get_ctx.a
    ${CMAKE_BINARY_DIR}/_deps/ruy-build/ruy/libruy_context.a
    ${CMAKE_BINARY_DIR}/_deps/ruy-build/ruy/libruy_frontend.a
    ${CMAKE_BINARY_DIR}/_deps/ruy-build/ruy/libruy_kernel_arm.a
    ${CMAKE_BINARY_DIR}/_deps/ruy-build/ruy/libruy_kernel_avx.a
    ${CMAKE_BINARY_DIR}/_deps/ruy-build/ruy/libruy_kernel_avx2_fma.a
    ${CMAKE_BINARY_DIR}/_deps/ruy-build/ruy/libruy_kernel_avx512.a
    ${CMAKE_BINARY_DIR}/_deps/ruy-build/ruy/libruy_apply_multiplier.a
    ${CMAKE_BINARY_DIR}/_deps/ruy-build/ruy/libruy_pack_arm.a
    ${CMAKE_BINARY_DIR}/_deps/ruy-build/ruy/libruy_pack_avx.a
    ${CMAKE_BINARY_DIR}/_deps/ruy-build/ruy/libruy_pack_avx2_fma.a
    ${CMAKE_BINARY_DIR}/_deps/ruy-build/ruy/libruy_pack_avx512.a
    ${CMAKE_BINARY_DIR}/_deps/ruy-build/ruy/libruy_prepare_packed_matrices.a
    ${CMAKE_BINARY_DIR}/_deps/ruy-build/ruy/libruy_trmul.a
    ${CMAKE_BINARY_DIR}/_deps/ruy-build/ruy/libruy_ctx.a
    ${CMAKE_BINARY_DIR}/_deps/ruy-build/ruy/libruy_allocator.a
    ${CMAKE_BINARY_DIR}/_deps/ruy-build/ruy/libruy_prepacked_cache.a
    ${CMAKE_BINARY_DIR}/_deps/ruy-build/ruy/libruy_system_aligned_alloc.a
    ${CMAKE_BINARY_DIR}/_deps/ruy-build/ruy/libruy_have_built_path_for_avx.a
    ${CMAKE_BINARY_DIR}/_deps/ruy-build/ruy/libruy_have_built_path_for_avx2_fma.a
    ${CMAKE_BINARY_DIR}/_deps/ruy-build/ruy/libruy_have_built_path_for_avx512.a
    ${CMAKE_BINARY_DIR}/_deps/ruy-build/ruy/libruy_thread_pool.a
    ${CMAKE_BINARY_DIR}/_deps/ruy-build/ruy/libruy_blocking_counter.a
    ${CMAKE_BINARY_DIR}/_deps/ruy-build/ruy/libruy_wait.a
    ${CMAKE_BINARY_DIR}/_deps/ruy-build/ruy/libruy_denormal.a
    ${CMAKE_BINARY_DIR}/_deps/ruy-build/ruy/libruy_block_map.a
    ${CMAKE_BINARY_DIR}/_deps/ruy-build/ruy/libruy_tune.a
    ${CMAKE_BINARY_DIR}/_deps/ruy-build/ruy/libruy_cpuinfo.a
    ${CMAKE_BINARY_DIR}/_deps/cpuinfo-build/libcpuinfo.a
    ${CMAKE_BINARY_DIR}/_deps/ruy-build/ruy/profiler/libruy_profiler_instrumentation.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/status/libabsl_statusor.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/status/libabsl_status.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/debugging/libabsl_leak_check.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/base/libabsl_strerror.a
    ${CMAKE_BINARY_DIR}/_deps/flatbuffers-build/libflatbuffers.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/container/libabsl_raw_hash_set.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/strings/libabsl_cord.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/strings/libabsl_cordz_info.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/strings/libabsl_cord_internal.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/strings/libabsl_cordz_functions.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/strings/libabsl_cordz_handle.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/crc/libabsl_crc_cord_state.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/crc/libabsl_crc32c.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/strings/libabsl_str_format_internal.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/crc/libabsl_crc_internal.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/crc/libabsl_crc_cpu_detect.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/container/libabsl_hashtablez_sampler.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/profiling/libabsl_exponential_biased.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/synchronization/libabsl_synchronization.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/debugging/libabsl_stacktrace.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/debugging/libabsl_borrowed_fixup_buffer.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/hash/libabsl_hash.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/hash/libabsl_city.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/debugging/libabsl_symbolize.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/debugging/libabsl_debugging_internal.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/debugging/libabsl_demangle_internal.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/debugging/libabsl_demangle_rust.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/debugging/libabsl_decode_rust_punycode.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/debugging/libabsl_utf8_for_code_point.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/synchronization/libabsl_graphcycles_internal.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/synchronization/libabsl_kernel_timeout_internal.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/base/libabsl_malloc_internal.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/time/libabsl_time.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/strings/libabsl_strings.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/strings/libabsl_strings_internal.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/base/libabsl_throw_delegate.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/numeric/libabsl_int128.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/time/libabsl_civil_time.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/time/libabsl_time_zone.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/base/libabsl_tracing_internal.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/base/libabsl_base.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/base/libabsl_raw_logging_internal.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/base/libabsl_log_severity.a
    ${CMAKE_BINARY_DIR}/_deps/abseil-cpp-build/absl/base/libabsl_spinlock_wait.a
)
EOF

# Hook the wrapper target into the main build tree.
cat >> litert/CMakeLists.txt <<'EOF'
add_subdirectory(python_wrapper)
EOF

mkdir -p build
mkdir -p build/disabled_vendor_headers

emcmake cmake -S litert -B build \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_PREFIX_PATH="${PREFIX};${BUILD_PREFIX}" \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DCMAKE_CROSSCOMPILING_EMULATOR=node \
    -DOVERRIDABLE_FETCH_CONTENT_GIT_REPOSITORY_AND_TAG_TO_URL=ON \
    -DBUILD_SHARED_LIBS=OFF \
    -DLITERT_BUILD_TESTS=OFF \
    -DLITERT_ENABLE_GPU=OFF \
    -DLITERT_ENABLE_NPU=OFF \
    -DLITERT_ENABLE_QUALCOMM=OFF \
    -DLITERT_ENABLE_SAMSUNG=OFF \
    -DNEUROPILOT_HEADERS_DIR="${SRC_DIR}/build/disabled_vendor_headers" \
    -DQAIRT_HEADERS_DIR="${SRC_DIR}/build/disabled_vendor_headers" \
    -DLITECORE_HEADERS_DIR="${SRC_DIR}/build/disabled_vendor_headers" \
    -DTENSORFLOW_SOURCE_DIR="${SRC_DIR}/third_party/tensorflow" \
    -DTFLITE_ENABLE_GPU=OFF \
    -DTFLITE_ENABLE_XNNPACK=OFF \
    -DTFLITE_HOST_TOOLS_DIR="${BUILD_PREFIX}/bin"

emmake ninja -C build -j"${CPU_COUNT}" \
    tensorflow-lite \
    litert_c_api \
    litert_cc_api \
    litert_cc_internal \
    litert_core \
    litert_core_model \
    litert_logging \
    litert_runtime \
    _ai_edge_litert

mkdir -p "${PREFIX}/include"
find litert -type f \( -name '*.h' -o -name '*.hpp' \) -exec cp --parents "{}" "${PREFIX}/include/" \;
cp -R build/include/. "${PREFIX}/include/"

mkdir -p "${PREFIX}/lib"
for lib_name in \
    libtensorflow-lite.a \
    liblitert_c_api.a \
    liblitert_cc_api.a \
    liblitert_cc_internal.a \
    liblitert_core.a \
    liblitert_core_model.a \
    liblitert_logging.a \
    liblitert_runtime.a
do
    lib_path=$(find build -name "${lib_name}" -print -quit)
    if [[ -z "${lib_path}" ]]; then
        echo "Missing expected library ${lib_name}" >&2
        exit 1
    fi
    cp "${lib_path}" "${PREFIX}/lib/"
done

mkdir -p "${PREFIX}/lib/cmake/litert"
cat > "${PREFIX}/lib/cmake/litert/litertConfig.cmake" <<'EOF'
get_filename_component(_LITERT_IMPORT_PREFIX "${CMAKE_CURRENT_LIST_FILE}" PATH)
get_filename_component(_LITERT_IMPORT_PREFIX "${_LITERT_IMPORT_PREFIX}" PATH)
get_filename_component(_LITERT_IMPORT_PREFIX "${_LITERT_IMPORT_PREFIX}" PATH)
get_filename_component(_LITERT_IMPORT_PREFIX "${_LITERT_IMPORT_PREFIX}" PATH)

set(_LITERT_INCLUDE_DIR "${_LITERT_IMPORT_PREFIX}/include")
set(LITERT_STATIC_LIBRARIES
    "${_LITERT_IMPORT_PREFIX}/lib/liblitert_cc_api.a"
    "${_LITERT_IMPORT_PREFIX}/lib/liblitert_c_api.a"
    "${_LITERT_IMPORT_PREFIX}/lib/liblitert_cc_internal.a"
    "${_LITERT_IMPORT_PREFIX}/lib/liblitert_core.a"
    "${_LITERT_IMPORT_PREFIX}/lib/liblitert_core_model.a"
    "${_LITERT_IMPORT_PREFIX}/lib/liblitert_logging.a"
    "${_LITERT_IMPORT_PREFIX}/lib/liblitert_runtime.a"
    "${_LITERT_IMPORT_PREFIX}/lib/libtensorflow-lite.a"
)

foreach(_litert_lib IN LISTS LITERT_STATIC_LIBRARIES)
    if(NOT EXISTS "${_litert_lib}")
        message(FATAL_ERROR "litert: expected library not found at ${_litert_lib}")
    endif()
endforeach()

if(NOT TARGET litert::litert_cc_headers)
    add_library(litert::litert_cc_headers INTERFACE IMPORTED)
    set_target_properties(litert::litert_cc_headers PROPERTIES
        INTERFACE_COMPILE_FEATURES cxx_std_20
        INTERFACE_INCLUDE_DIRECTORIES "${_LITERT_INCLUDE_DIR}"
    )
endif()

if(NOT TARGET litert::litert_cc_api)
    add_library(litert::litert_cc_api INTERFACE IMPORTED)
    set_target_properties(litert::litert_cc_api PROPERTIES
        INTERFACE_COMPILE_FEATURES cxx_std_20
        INTERFACE_INCLUDE_DIRECTORIES "${_LITERT_INCLUDE_DIR}"
        INTERFACE_LINK_LIBRARIES "litert::litert_cc_headers;${LITERT_STATIC_LIBRARIES}"
    )

    if(EMSCRIPTEN)
        set_property(TARGET litert::litert_cc_api APPEND PROPERTY
            INTERFACE_LINK_OPTIONS
                -sUSE_WEBGPU=1
                -sALLOW_MEMORY_GROWTH=1
        )
    endif()
endif()

set(LITERT_INCLUDE_DIRS "${_LITERT_INCLUDE_DIR}")
set(LITERT_LIBRARIES "${LITERT_STATIC_LIBRARIES}")
set(LITERT_VERSION "2.1.5")

unset(_LITERT_IMPORT_PREFIX)
unset(_LITERT_INCLUDE_DIR)
unset(_litert_lib)
EOF

# ============================================================================
# Python bindings: ONE merged pybind11 SIDE_MODULE with the static runtime
# embedded (upstream ":emscripten" static configuration). The three upstream
# pybind modules become submodules of a single "_ai_edge_litert" module so
# there is exactly one registries copy per process (no split-brain), and the
# environment's runtime_path option is inert because nothing dlopens in the
# static build.
# ============================================================================
WRAP="litert/python/litert_wrapper"
TENSORFLOW_SOURCE_DIR="$(pwd)/third_party/tensorflow"
LITERT_SOURCE_DIR="$(pwd)/litert"

# Rename the three PYBIND11_MODULE(...) definitions into plain init functions
# (the umbrella module below assembles them as submodules).
sed -i 's/PYBIND11_MODULE(_pywrap_litert_compiled_model_wrapper, m)/void init_pywrap_litert_compiled_model_wrapper(py::module_ \&m)/' \
    "${WRAP}/compiled_model_wrapper/compiled_model_wrapper_pybind11.cc"
sed -i 's/PYBIND11_MODULE(_pywrap_litert_environment_wrapper, m)/void init_pywrap_litert_environment_wrapper(py::module_ \&m)/' \
    "${WRAP}/environment_wrapper/environment_wrapper_pybind11.cc"
sed -i 's/PYBIND11_MODULE(_pywrap_litert_tensor_buffer_wrapper, m)/void init_pywrap_litert_tensor_buffer_wrapper(py::module_ \&m)/' \
    "${WRAP}/tensor_buffer_wrapper/tensor_buffer_wrapper_pybind11.cc"

# ----------------------------------------------------------------------------
# Assemble site-packages/ai_edge_litert/ (wheel layout, flattened).
# The module itself was built as target "_ai_edge_litert" inside the main
# cmake tree (litert/python_wrapper/), see the top of this script.
# ----------------------------------------------------------------------------
SP="${PREFIX}/lib/python${PY_VER}/site-packages"
mkdir -p "${SP}/ai_edge_litert"

cp "${WRAP}"/compiled_model_wrapper/*.py   "${SP}/ai_edge_litert/"
cp "${WRAP}"/environment_wrapper/*.py      "${SP}/ai_edge_litert/"
cp "${WRAP}"/tensor_buffer_wrapper/*.py    "${SP}/ai_edge_litert/"
cp "${WRAP}"/compiled_model_wrapper/*.pyi  "${SP}/ai_edge_litert/"
cp "${WRAP}"/environment_wrapper/*.pyi     "${SP}/ai_edge_litert/"
cp "${WRAP}"/tensor_buffer_wrapper/*.pyi   "${SP}/ai_edge_litert/"
cp "$(find build -name '_ai_edge_litert.so' -print -quit)" "${SP}/ai_edge_litert/"
# tiny ADD model used by the pytester test (rides inside the package: the
# pytester mounts only carry collected test_*.py files)
mkdir -p "${SP}/ai_edge_litert/testdata"
cp "${TENSORFLOW_SOURCE_DIR}/tensorflow/lite/testdata/add.bin" \
    "${SP}/ai_edge_litert/testdata/"

cat > "${SP}/ai_edge_litert/__init__.py" <<'EOF'
"""LiteRT Python bindings for emscripten-wasm32.

Exposes the CompiledModel, Environment and TensorBuffer wrappers as a single
merged side module (``_ai_edge_litert``); the three upstream pybind modules
are submodules of it. This mirrors the upstream wheel's flat layout.
"""

__version__ = "2.1.5"

from ai_edge_litert import _ai_edge_litert as _core

_pywrap_litert_compiled_model_wrapper = _core._pywrap_litert_compiled_model_wrapper
_pywrap_litert_environment_wrapper = _core._pywrap_litert_environment_wrapper
_pywrap_litert_tensor_buffer_wrapper = _core._pywrap_litert_tensor_buffer_wrapper

__all__ = [
    "__version__",
    "_pywrap_litert_compiled_model_wrapper",
    "_pywrap_litert_environment_wrapper",
    "_pywrap_litert_tensor_buffer_wrapper",
]
EOF
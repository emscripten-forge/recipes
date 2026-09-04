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
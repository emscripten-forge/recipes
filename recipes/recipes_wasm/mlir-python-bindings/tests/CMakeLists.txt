cmake_minimum_required(VERSION 3.20)
project(test_mlir_exports LANGUAGES NONE)

# The Wasm execution engine's exports reference LLD targets.
find_package(LLD $ENV{PKG_VERSION} EXACT REQUIRED CONFIG)
find_program(MLIR_TABLEGEN_EXE NAMES mlir-tblgen REQUIRED)
set(expected_tablegen "${MLIR_TABLEGEN_EXE}")
find_package(MLIR $ENV{PKG_VERSION} EXACT REQUIRED CONFIG)
if(NOT MLIR_TABLEGEN_EXE STREQUAL expected_tablegen)
  message(FATAL_ERROR "MLIRConfig replaced the native TableGen executable")
endif()
if(NOT MLIR_TABLEGEN_TARGET STREQUAL expected_tablegen)
  message(FATAL_ERROR "TableGen dependency does not name the native executable")
endif()

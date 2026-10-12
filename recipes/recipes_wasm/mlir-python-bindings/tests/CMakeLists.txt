cmake_minimum_required(VERSION 3.20)
project(test_mlir_exports LANGUAGES NONE)

# The Wasm execution engine's exports reference LLD targets.
find_package(LLD $ENV{PKG_VERSION} EXACT REQUIRED CONFIG)
find_package(MLIR $ENV{PKG_VERSION} EXACT REQUIRED CONFIG)

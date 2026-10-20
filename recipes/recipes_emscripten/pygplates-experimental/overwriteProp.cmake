set_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS TRUE)
# pygplates is add_library(... MODULE ...), which uses CMAKE_MODULE_LIBRARY_*
# flags, not CMAKE_SHARED_LIBRARY_*. Set both so a plain SHARED target and
# our MODULE python extension both get -sSIDE_MODULE=1 -sEXPORT_ALL=1 (needed
# so PyInit_pygplates is exported to the loader).
set(_EMFORGE_SIDE_MODULE_FLAGS "-s WASM_BIGINT -s SIDE_MODULE=1 -s EXPORT_ALL=1")
set(CMAKE_SHARED_LIBRARY_CREATE_C_FLAGS "${_EMFORGE_SIDE_MODULE_FLAGS}")
set(CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS "${_EMFORGE_SIDE_MODULE_FLAGS}")
set(CMAKE_MODULE_LIBRARY_CREATE_C_FLAGS "${_EMFORGE_SIDE_MODULE_FLAGS}")
set(CMAKE_MODULE_LIBRARY_CREATE_CXX_FLAGS "${_EMFORGE_SIDE_MODULE_FLAGS}")
set(CMAKE_STRIP FALSE)

# Force module-mode FindBoost. Boost's shipped BoostConfig.cmake performs an
# architecture check by inspecting the compiled .a files; it doesn't recognize
# wasm bytecode and defaults to "looks 64-bit", rejecting our wasm32 static
# libs with "libboost_*.a (64 bit, need 32)". FindBoost skips that check.
# CMP0167=OLD keeps FindBoost usable under CMake 4+.
set(Boost_NO_BOOST_CMAKE TRUE)
set(Boost_USE_STATIC_LIBS TRUE)
if(POLICY CMP0167)
    cmake_policy(SET CMP0167 OLD)
endif()

# Qt6Core depends on WrapRt. Qt's FindWrapRt.cmake runs check_cxx_source_compiles
# for clock_gettime/shm_open, which fail under the emscripten cross-toolchain
# (link step doesn't produce a runnable native binary). The module has an
# early-return path when the target already exists, so pre-create an empty
# INTERFACE target: on emscripten, clock_gettime and shm_open live in libc,
# no separate librt linkage is needed.
if(NOT TARGET WrapRt::WrapRt)
    add_library(WrapRt::WrapRt INTERFACE IMPORTED)
endif()

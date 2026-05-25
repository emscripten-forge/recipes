cmake_minimum_required(VERSION 3.15)
project(curl_tests C)

set(CMAKE_C_STANDARD 11)

# Find OpenSSL in CONFIG mode first so that CURLConfig.cmake reuses the
# static-library targets from emscripten-forge's OpenSSLConfig.cmake
# instead of falling back to FindOpenSSL.cmake (which finds .so files).
find_package(OpenSSL REQUIRED CONFIG)

# Pre-set ZLIB paths so FindZLIB.cmake finds the static .a library
# instead of the .so shared library (which wasm-ld cannot link).
# Use CACHE to persist these so CURLConfig.cmake's find_dependency(ZLIB)
# can also see them.
set(ZLIB_LIBRARY "${CMAKE_PREFIX_PATH}/lib/libz.a" CACHE FILEPATH "Path to zlib static library")
set(ZLIB_INCLUDE_DIR "${CMAKE_PREFIX_PATH}/include" CACHE PATH "Path to zlib include directory")
find_package(ZLIB REQUIRED)

# Find CURL using CONFIG mode to use CURLConfig.cmake
find_package(CURL REQUIRED CONFIG)

# Test executable
add_executable(test_curl test_curl.c)
target_link_libraries(test_curl PRIVATE CURL::libcurl)

cmake_minimum_required(VERSION 3.20)
project(test_libheif CXX)

# Find libheif - it installs a CMake config in lib/cmake/libheif/
find_package(libheif REQUIRED)

add_executable(test_libheif test_libheif.cpp)
target_link_libraries(test_libheif PRIVATE heif)

if(EMSCRIPTEN)
    target_link_options(test_libheif PRIVATE
        -sALLOW_MEMORY_GROWTH=1
        -sINITIAL_MEMORY=64MB
    )
endif()

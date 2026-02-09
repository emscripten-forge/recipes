cmake_minimum_required(VERSION 3.20)
project(sparrow_ipc_test CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# For emscripten, find lz4 and create alias if needed (workaround for conda packages)
find_library(LZ4_LIBRARY NAMES lz4 liblz4)
if(LZ4_LIBRARY AND NOT TARGET lz4::lz4)
    add_library(lz4::lz4 UNKNOWN IMPORTED)
    set_target_properties(lz4::lz4 PROPERTIES IMPORTED_LOCATION "${LZ4_LIBRARY}")
endif()

find_package(sparrow-ipc REQUIRED)

add_executable(test_simple test_simple.cpp)
target_link_libraries(test_simple PRIVATE sparrow-ipc::sparrow-ipc)

# Enable main module for dynamic linking with side modules
set_target_properties(test_simple PROPERTIES 
  LINK_FLAGS "-s MAIN_MODULE=2"
)

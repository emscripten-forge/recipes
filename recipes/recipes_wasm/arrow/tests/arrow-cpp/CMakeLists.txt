cmake_minimum_required(VERSION 3.20)
project(arrow_test CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Arrow REQUIRED)

add_executable(test_arrow test_arrow.cpp)
target_link_libraries(test_arrow PRIVATE Arrow::arrow_static)

# Enable memory growth and set initial memory for WebAssembly
if(EMSCRIPTEN)
    target_link_options(test_arrow PRIVATE
        -sALLOW_MEMORY_GROWTH=1
        -sINITIAL_MEMORY=512MB
        -sSTACK_SIZE=16MB
        -sMAXIMUM_MEMORY=2GB
    )
endif()

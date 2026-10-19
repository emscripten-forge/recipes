cmake_minimum_required(VERSION 3.15)
project(test_quirc C)

find_package(quirc REQUIRED)

add_executable(test_quirc test_quirc.c)
target_link_libraries(test_quirc PRIVATE quirc::quirc)

if(EMSCRIPTEN)
    target_link_options(test_quirc PRIVATE
        -sALLOW_MEMORY_GROWTH=1
        -sINITIAL_MEMORY=64MB
    )
endif()

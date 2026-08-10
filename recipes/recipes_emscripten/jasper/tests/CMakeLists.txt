cmake_minimum_required(VERSION 3.20)
project(test_jasper C)

find_package(JasPer REQUIRED)

add_executable(test_jasper test_jasper.c)
target_link_libraries(test_jasper PRIVATE JasPer::libjasper)

if(EMSCRIPTEN)
    target_link_options(test_jasper PRIVATE
        -sALLOW_MEMORY_GROWTH=1
        -sINITIAL_MEMORY=64MB
    )
endif()

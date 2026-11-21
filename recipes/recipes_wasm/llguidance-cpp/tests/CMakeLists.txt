cmake_minimum_required(VERSION 3.20)
project(llguidance_test CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(llguidance REQUIRED)

add_executable(test_llguidance test_llguidance.cpp)
target_link_libraries(test_llguidance PRIVATE llguidance::llguidance)

if(EMSCRIPTEN)
    target_link_options(test_llguidance PRIVATE
        -sALLOW_MEMORY_GROWTH=1
        -sINITIAL_MEMORY=64MB
    )
endif()

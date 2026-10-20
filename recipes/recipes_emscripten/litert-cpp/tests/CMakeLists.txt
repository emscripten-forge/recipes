cmake_minimum_required(VERSION 3.20)
project(litert_test CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(litert REQUIRED CONFIG)

add_executable(test_litert test_litert.cpp)
target_link_libraries(test_litert PRIVATE litert::litert_cc_api)

if(EMSCRIPTEN)
    target_link_options(test_litert PRIVATE
        -sENVIRONMENT=node
        -sEXIT_RUNTIME=1
    )
endif()
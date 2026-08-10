cmake_minimum_required(VERSION 3.20)
project(minja_test CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(nlohmann_json REQUIRED)

add_executable(test_minja test_minja.cpp)
target_include_directories(test_minja PRIVATE $ENV{PREFIX}/include)
target_link_libraries(test_minja PRIVATE nlohmann_json::nlohmann_json)

if(EMSCRIPTEN)
    target_link_options(test_minja PRIVATE
        -sALLOW_MEMORY_GROWTH=1
        -sINITIAL_MEMORY=64MB
    )
endif()

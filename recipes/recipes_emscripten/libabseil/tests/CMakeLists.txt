cmake_minimum_required(VERSION 3.20)
project(abseil_test CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(absl REQUIRED)

add_executable(test_abseil test_abseil.cpp)
target_link_libraries(test_abseil PRIVATE
    absl::strings
    absl::str_format
    absl::status
    absl::statusor
    absl::flat_hash_map
    absl::flat_hash_set
    absl::base
    absl::log
    absl::time
)

if(EMSCRIPTEN)
    target_link_options(test_abseil PRIVATE
        -sALLOW_MEMORY_GROWTH=1
        -sINITIAL_MEMORY=64MB
    )
endif()

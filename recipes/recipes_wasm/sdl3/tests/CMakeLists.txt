cmake_minimum_required(VERSION 3.20)
project(sdl3_consumer_test C)

find_package(SDL3 CONFIG REQUIRED)

add_executable(test_sdl3 test_sdl3.c)
target_link_libraries(test_sdl3 PRIVATE SDL3::SDL3)
target_link_options(test_sdl3 PRIVATE
    "SHELL:-sALLOW_MEMORY_GROWTH=1"
    "SHELL:-sMAXIMUM_MEMORY=1gb"
    "SHELL:-sEXIT_RUNTIME=1"
)

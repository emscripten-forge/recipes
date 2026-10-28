cmake_minimum_required(VERSION 3.20)
project(sdl3_demo C)

find_package(SDL3 CONFIG REQUIRED)

add_executable(sdl3-demo main.c)
target_link_libraries(sdl3-demo PRIVATE SDL3::SDL3)

set_target_properties(sdl3-demo PROPERTIES SUFFIX ".html")
target_link_options(sdl3-demo PRIVATE
    "SHELL:-sALLOW_MEMORY_GROWTH=1"
    "SHELL:-sMAXIMUM_MEMORY=1gb"
)

install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/sdl3-demo.html"
    "${CMAKE_CURRENT_BINARY_DIR}/sdl3-demo.js"
    "${CMAKE_CURRENT_BINARY_DIR}/sdl3-demo.wasm"
    DESTINATION share/sdl3-demo
)
install(FILES README.md DESTINATION share/sdl3-demo)

cmake_minimum_required(VERSION 3.19)
project(qt-calculator LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

# Qt6 wasm target-finalization needs helpers that qt-cmake normally injects
# via Qt's toolchain file. emscripten-forge invokes cmake with
# Emscripten.cmake directly, so include the wasm helpers by hand.
find_file(QT_WASM_HELPERS
    NAMES QtPublicWasmToolchainHelpers.cmake
    PATHS "$ENV{PREFIX}/lib/cmake/Qt6"
          "$ENV{PREFIX}/lib/cmake/Qt6Core"
    NO_DEFAULT_PATH NO_CMAKE_FIND_ROOT_PATH REQUIRED)
include("${QT_WASM_HELPERS}")

find_package(Qt6 REQUIRED COMPONENTS Widgets)

# Source files sit alongside this CMakeLists after build.sh copies us
# into Qt's examples/widgets/widgets/calculator/ directory.
qt_add_executable(qt-calculator
    main.cpp
    button.cpp
    calculator.cpp
)

target_link_libraries(qt-calculator PRIVATE Qt6::Widgets)

# qt6-main is built with -feature-wasm-jspi, which propagates -sJSPI via
# INTERFACE. Repeating explicitly is belt-and-braces.
target_link_options(qt-calculator PRIVATE -sJSPI=1)

# Match qt6-main's wasm-exception ABI per emscripten-forge convention.
target_compile_options(qt-calculator PRIVATE -fwasm-exceptions)
target_link_options(qt-calculator PRIVATE -fwasm-exceptions)

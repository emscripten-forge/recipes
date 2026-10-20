cmake_minimum_required(VERSION 3.19)
project(qhexedit LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

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

# QHexEdit2's example app pulls the widget library sources from ../src and
# the app sources (mainwindow, dialogs) from the example directory itself.
qt_add_executable(qhexedit
    example/main.cpp
    example/mainwindow.cpp
    example/optionsdialog.cpp
    example/searchdialog.cpp
    example/optionsdialog.ui
    example/searchdialog.ui
    example/qhexedit.qrc
    src/qhexedit.cpp
    src/chunks.cpp
    src/commands.cpp
    src/color_manager.cpp
)

target_include_directories(qhexedit PRIVATE src example)
target_compile_definitions(qhexedit PRIVATE QHEXEDIT_EXPORTS)
target_link_libraries(qhexedit PRIVATE Qt6::Widgets)

# qt6-main is built with -feature-wasm-jspi, which propagates -sJSPI via
# INTERFACE. Repeating explicitly is belt-and-braces.
target_link_options(qhexedit PRIVATE -sJSPI=1)

# Match qt6-main's wasm-exception ABI per emscripten-forge convention.
target_compile_options(qhexedit PRIVATE -fwasm-exceptions)
target_link_options(qhexedit PRIVATE -fwasm-exceptions)

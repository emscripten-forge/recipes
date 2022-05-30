cmake_minimum_required(VERSION 3.9)
project(pytest_driver VERSION 0.1.0 DESCRIPTION "pytest_driver description")


option(ENV_NODE "Build for the node env" OFF)

if(ENV_NODE)
    SET(ENVIRONMENT "node")
else()
    SET(ENVIRONMENT "web")
endif()

set(EM_FLAGS "${EM_FLAGS} -s ENVIRONMENT=${ENVIRONMENT} --bind -s DISABLE_EXCEPTION_THROWING=0 -s DISABLE_EXCEPTION_CATCHING=0  -s NO_DISABLE_EXCEPTION_CATCHING -fexceptions ")
set(EM_FLAGS "${EM_FLAGS} -fPIC -s LZ4=1")
set(EM_FLAGS "${EM_FLAGS} --post-js post.js")
set(EM_FLAGS "${EM_FLAGS} --pre-js pre.js")
set(EM_FLAGS "${EM_FLAGS} -s ALLOW_MEMORY_GROWTH")

set(EM_LINKER_FLAGS "${EM_LINKER_FLAGS} -WASM=1 -s FORCE_FILESYSTEM=1 -s MODULARIZE -s ERROR_ON_UNDEFINED_SYMBOLS=1")
set(EM_LINKER_FLAGS "${EM_LINKER_FLAGS} -s EXPORT_NAME=\"createModule\" -s EXPORT_ES6=0 -s USE_ES6_IMPORT_META=0 -s ERROR_ON_UNDEFINED_SYMBOLS=1")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${EM_FLAGS} ${EM_LINKER_FLAGS}")
set(CMAKE_LINKER_FLAGS "${CMAKE_LINKER_FLAGS}  ${EM_FLAGS} ${EM_LINKER_FLAGS}")

find_package(pybind11 REQUIRED CONFIG)
set(pyjs_REQUIRED_VERSION 0.1.0)
find_package(pyjs ${pyjs_REQUIRED_VERSION} REQUIRED)

SET(PYTHON_UTIL_LIBS 
    $ENV{PREFIX}/lib/libbz2.a
    $ENV{PREFIX}/lib/libz.a
    $ENV{PREFIX}/lib/libsqlite3.a
    $ENV{PREFIX}/lib/libffi.a
)
configure_file(${pyjs_PRE_JS_PATH}   ${CMAKE_CURRENT_BINARY_DIR}/pre.js  COPYONLY)
configure_file(post.js               ${CMAKE_CURRENT_BINARY_DIR}/post.js COPYONLY)

add_executable(pytest_driver pytest_driver.cpp)

target_link_libraries(pytest_driver PRIVATE ${PYTHON_UTIL_LIBS} pybind11::embed pyjs)

set_target_properties(pytest_driver PROPERTIES 
    LINK_FLAGS "-s MAIN_MODULE=1  -lstdc++ ${EM_FLAGS} "
    CXX_FLAGS  "${EM_FLAGS} -fPIC"
)

include(GNUInstallDirs)
install(TARGETS pytest_driver
    ARCHIVE DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES
    "$<TARGET_FILE_DIR:pytest_driver>/pytest_driver.js"
    "$<TARGET_FILE_DIR:pytest_driver>/pytest_driver.wasm"
    DESTINATION ${CMAKE_INSTALL_BINDIR})

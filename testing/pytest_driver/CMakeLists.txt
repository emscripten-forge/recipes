cmake_minimum_required(VERSION 3.9)
project(pytest_driver VERSION 0.1.0 DESCRIPTION "pytest_driver description")


option(ENV_NODE "Build for the node env" OFF)



find_package(pybind11 REQUIRED CONFIG)
set(pyjs_REQUIRED_VERSION 0.2.0)
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


if(ENV_NODE)
    SET(ENVIRONMENT "node")
    target_compile_definitions(pytest_driver PUBLIC -DPYTEST_DRIVER_NODE)  # -D removed
else()
    SET(ENVIRONMENT "web,worker")
     target_compile_definitions(pytest_driver PUBLIC -DPYTEST_DRIVER_WEB)  # -D removed
endif()



target_compile_options(pytest_driver PRIVATE -fPIC)


target_compile_options(pytest_driver
    PUBLIC --std=c++17
    PUBLIC -Wno-deprecated
    PUBLIC "SHELL: --bind"
    PUBLIC "SHELL: -s ENVIRONMENT=${ENVIRONMENT}"
    PUBLIC "SHELL: -fwasm-exceptions"
    PUBLIC "SHELL: -s FORCE_FILESYSTEM"
    PUBLIC "SHELL: -s LZ4=1"
)

target_link_options(pytest_driver
    PUBLIC --bind
    PUBLIC -Wno-unused-command-line-argument
    PUBLIC "SHELL: --bind"
    PUBLIC "SHELL: -s MODULARIZE=1"
    PUBLIC "SHELL: -s EXPORT_NAME=\"createModule\""
    PUBLIC "SHELL: -s EXPORT_ES6=0"
    PUBLIC "SHELL: -s USE_ES6_IMPORT_META=0"
    PUBLIC "SHELL: -s DEMANGLE_SUPPORT=0"
    PUBLIC "SHELL: -s ASSERTIONS=0"
    PUBLIC "SHELL: -s ALLOW_MEMORY_GROWTH=1"
    PUBLIC "SHELL: -s EXIT_RUNTIME=1"
    PUBLIC "SHELL: -s WASM=1"
    PUBLIC "SHELL: -s USE_PTHREADS=0"
    PUBLIC "SHELL: -fwasm-exceptions"
    PUBLIC "SHELL: -s MAIN_MODULE=1"
    PUBLIC "SHELL: -s ENVIRONMENT=${ENVIRONMENT}"
    PUBLIC "SHELL: -s TOTAL_STACK=512mb"
    PUBLIC "SHELL: -s INITIAL_MEMORY=1024mb"
    PUBLIC "SHELL: -s FORCE_FILESYSTEM"
    PUBLIC "SHELL: -s LZ4=1"
    PUBLIC "SHELL: --post-js post.js"
    PUBLIC "SHELL: --pre-js pre.js"
)





include(GNUInstallDirs)
install(TARGETS pytest_driver
    ARCHIVE DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES
    "$<TARGET_FILE_DIR:pytest_driver>/pytest_driver.js"
    "$<TARGET_FILE_DIR:pytest_driver>/pytest_driver.wasm"
    DESTINATION ${CMAKE_INSTALL_BINDIR})

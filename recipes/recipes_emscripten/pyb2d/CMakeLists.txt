
cmake_minimum_required(VERSION 3.1)
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules)
project (pyb2d)

set_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS TRUE)
set(CMAKE_SHARED_LIBRARY_CREATE_C_FLAGS "-s SIDE_MODULE=1")
set(CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS "-s SIDE_MODULE=1")
set(CMAKE_STRIP FALSE)  # used by default in pybind11 on .so modules

set(PROJECT_INCLUDE_DIR    ${CMAKE_CURRENT_SOURCE_DIR}/include)
set(CPP_ROOT_FOLDER_NAME   pyb2d)
include_directories(${PROJECT_INCLUDE_DIR})

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Python
# ============
OPTION(BUILD_PYTHON "${PROJECT_NAME} python binding" ON)
OPTION(PYB2D_LIQUID_FUN "${PROJECT_NAME} liquidfun" ON)
if(BUILD_PYTHON)
    add_subdirectory(python)
    # add_subdirectory(old_python)
endif()

if(PYB2D_LIQUID_FUN)
    add_compile_definitions(PYB2D_LIQUID_FUN)
    # add_compile_definitions(PYB2D_OLD_BOX2D)
endif()

# Installation
# ============

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)


set(${PROJECT_NAME}_CMAKECONFIG_INSTALL_DIR "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}" CACHE
    STRING "install path for ${PROJECT_NAME}Config.cmake")

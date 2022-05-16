
cmake_minimum_required(VERSION 3.1)
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules)
project (pybox2d)


set(PROJECT_INCLUDE_DIR    ${CMAKE_CURRENT_SOURCE_DIR}/include)
set(CPP_ROOT_FOLDER_NAME   pybox2d)
include_directories(${PROJECT_INCLUDE_DIR})

# C++ 14
# ===========
include(CheckCXXCompilerFlag)
if (CMAKE_CXX_COMPILER_ID MATCHES "Clang" OR CMAKE_CXX_COMPILER_ID MATCHES "GNU" OR CMAKE_CXX_COMPILER_ID MATCHES "Intel")
    CHECK_CXX_COMPILER_FLAG("-std=c++14" HAS_CPP14_FLAG)
    if (HAS_CPP14_FLAG)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14")
    else()
        message(FATAL_ERROR "Unsupported compiler -- C++14 support required!")
    endif()
endif()   



# Python
# ============
OPTION(BUILD_PYTHON "${PROJECT_NAME} python binding" ON)
OPTION(PYBOX2D_LIQUID_FUN "${PROJECT_NAME} liquidfun" ON)
if(BUILD_PYTHON)
    add_subdirectory(python)
    # add_subdirectory(old_python)
endif()

if(PYBOX2D_LIQUID_FUN)
    add_compile_definitions(PYBOX2D_LIQUID_FUN)
    add_compile_definitions(PYBOX2D_OLD_BOX2D)
endif()

# Installation
# ============

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)


set(${PROJECT_NAME}_CMAKECONFIG_INSTALL_DIR "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}" CACHE
    STRING "install path for ${PROJECT_NAME}Config.cmake")

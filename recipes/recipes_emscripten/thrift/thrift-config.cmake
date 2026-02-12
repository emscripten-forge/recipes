# thrift-config.cmake
# CMake configuration file for Apache Thrift C++ library (Emscripten/WebAssembly)
#
# This file provides easy access to the Thrift library for CMake projects.
# It defines:
#   thrift::thrift - Main imported target
#   THRIFT_FOUND - Set to TRUE
#   THRIFT_VERSION - Version string
#   THRIFT_INCLUDE_DIRS - Include directories
#   THRIFT_LIBRARIES - Libraries to link

set(THRIFT_VERSION "0.22.0")

# Get the directory of this config file
get_filename_component(THRIFT_CMAKE_DIR "${CMAKE_CURRENT_LIST_FILE}" PATH)
get_filename_component(THRIFT_ROOT_DIR "${THRIFT_CMAKE_DIR}/../.." ABSOLUTE)

# Set include and library paths
set(THRIFT_INCLUDE_DIRS "${THRIFT_ROOT_DIR}/include")
set(THRIFT_LIBRARY_DIR "${THRIFT_ROOT_DIR}/lib")
set(THRIFT_LIBRARIES "${THRIFT_LIBRARY_DIR}/libthrift.a")

# Check if library exists
if(NOT EXISTS "${THRIFT_LIBRARIES}")
    set(THRIFT_FOUND FALSE)
    if(thrift_FIND_REQUIRED)
        message(FATAL_ERROR "Thrift library not found at ${THRIFT_LIBRARIES}")
    endif()
    return()
endif()

# Check if include directory exists
if(NOT EXISTS "${THRIFT_INCLUDE_DIRS}")
    set(THRIFT_FOUND FALSE)
    if(thrift_FIND_REQUIRED)
        message(FATAL_ERROR "Thrift include directory not found at ${THRIFT_INCLUDE_DIRS}")
    endif()
    return()
endif()

# Create imported target if it doesn't exist
if(NOT TARGET thrift::thrift)
    add_library(thrift::thrift STATIC IMPORTED)
    
    set_target_properties(thrift::thrift PROPERTIES
        IMPORTED_LOCATION "${THRIFT_LIBRARIES}"
        INTERFACE_INCLUDE_DIRECTORIES "${THRIFT_INCLUDE_DIRS}"
    )
    
    # Set dependencies
    # Thrift requires Boost (headers only), OpenSSL, and zlib
    find_package(Boost QUIET)
    if(Boost_FOUND OR TARGET Boost::headers)
        if(TARGET Boost::headers)
            set_property(TARGET thrift::thrift APPEND PROPERTY
                INTERFACE_LINK_LIBRARIES Boost::headers)
        endif()
    endif()
    
    # Link with OpenSSL if available
    find_package(OpenSSL QUIET)
    if(OPENSSL_FOUND)
        set_property(TARGET thrift::thrift APPEND PROPERTY
            INTERFACE_LINK_LIBRARIES OpenSSL::SSL OpenSSL::Crypto)
    endif()
    
    # Link with zlib if available
    find_package(ZLIB QUIET)
    if(ZLIB_FOUND)
        set_property(TARGET thrift::thrift APPEND PROPERTY
            INTERFACE_LINK_LIBRARIES ZLIB::ZLIB)
    endif()
endif()

# Set standard CMake find_package variables
set(THRIFT_FOUND TRUE)

# Print status message if requested
if(NOT thrift_FIND_QUIETLY)
    message(STATUS "Found Thrift: ${THRIFT_LIBRARIES} (found version \"${THRIFT_VERSION}\")")
endif()

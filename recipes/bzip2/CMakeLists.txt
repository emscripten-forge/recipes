cmake_minimum_required(VERSION 3.0)
cmake_policy(SET CMP0091 NEW)
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded" CACHE STRING "")

project(bzip2 C)
# add_compile_options(-fPIC)
message("CXXFLAGS: $ENV{CXXFLAGS}")
message("CFLAGS: $ENV{CFLAGS}")
message("CMAKE_POSITION_INDEPENDENT_CODE ${CMAKE_POSITION_INDEPENDENT_CODE}")

if(CMAKE_BUILD_TYPE STREQUAL Debug)
    add_definitions(-DBZ_DEBUG) # enable extra assertions
endif()

if(EMSCRIPTEN)
    add_definitions(-D_FILE_OFFSET_BITS=64)
endif()

set(BZ2_SOURCES
    blocksort.c
    huffman.c
    crctable.c
    randtable.c
    compress.c
    decompress.c
    bzlib.c)

add_library(bz2 ${BZ2_SOURCES})
set_target_properties(bz2 PROPERTIES
    DEBUG_POSTFIX d
    VERSION 1.0.6
    SOVERSION 1.0)
if(BUILD_SHARED_LIBS)
    target_compile_definitions(bz2 PRIVATE -DBZ_BUILD_DLL)
endif()

if(MSVC)
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)
    add_definitions(-D_CRT_SECURE_NO_DEPRECATE)
    add_definitions(-D_CRT_NONSTDC_NO_DEPRECATE)
endif()

install(TARGETS bz2
    RUNTIME DESTINATION bin
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib)

if(NOT BZIP2_SKIP_TOOLS)
    add_executable(bzip2 bzip2.c ${BZ2_SOURCES})
    add_executable(bzip2recover bzip2recover.c ${BZ2_SOURCES})
    install(TARGETS bzip2 bzip2recover DESTINATION tools/bzip2)
endif()

if(NOT BZIP2_SKIP_HEADERS)
    install(FILES bzlib.h DESTINATION include)
endif()

# the compiler flags for compiling C sources 
MESSAGE( STATUS "CMAKE_C_FLAGS: " ${CMAKE_C_FLAGS} )

# the compiler flags for compiling C++ sources 
MESSAGE( STATUS "CMAKE_CXX_FLAGS: " ${CMAKE_CXX_FLAGS} )
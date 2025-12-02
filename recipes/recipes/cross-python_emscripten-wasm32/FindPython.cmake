set_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS TRUE)
set(CMAKE_SHARED_LIBRARY_CREATE_C_FLAGS "-s SIDE_MODULE=1")
set(CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS "-s SIDE_MODULE=1")
set(CMAKE_STRIP FALSE)  # used by default in pybind11 on .so modules

# Indicate that Python and its components are found
set(Python_FOUND TRUE)
set(Python_Interpreter_FOUND TRUE)
set(Python_Development_FOUND TRUE)


set(PY_VER "$ENV{PY_VER}") # This should be set to the Python version you are using, e.g., "3.13"
set(MY_PYTHON_PREFIX "$ENV{PREFIX}") 

# Hardcode the Python interpreter path
set(Python_EXECUTABLE "$ENV{PYTHON}") 

execute_process(
  COMMAND "${Python_EXECUTABLE}" -c "import sys; print(sys.version_info[0])"
  OUTPUT_VARIABLE PYTHON_MAJOR_VERSION
  OUTPUT_STRIP_TRAILING_WHITESPACE
  RESULT_VARIABLE PYTHON_VERSION_MAJOR
)

execute_process(
  COMMAND "${Python_EXECUTABLE}" -c "import sys; print(sys.version_info[1])"
  OUTPUT_VARIABLE PYTHON_MAJOR_VERSION
  OUTPUT_STRIP_TRAILING_WHITESPACE
  RESULT_VARIABLE PYTHON_VERSION_MINOR
)

execute_process(
  COMMAND "${Python_EXECUTABLE}" -c "import sys; print(sys.version_info[2])"
  OUTPUT_VARIABLE PYTHON_MAJOR_VERSION
  OUTPUT_STRIP_TRAILING_WHITESPACE
  RESULT_VARIABLE PYTHON_VERSION_PATCH
)

set(Python_VERSION_STRING "${Python_VERSION_MAJOR}.${Python_VERSION_MINOR}.${Python_VERSION_PATCH}")


set(Python_LIBRARIES "${MY_PYTHON_PREFIX}/lib/libpython${PY_VER}.a")
set(Python_Development_LIBRARIES "${MY_PYTHON_PREFIX}/lib/libpython${PY_VER}.a") # Often the same as Python_LIBRARIES for development

set(Python_INCLUDE_DIRS
    "${MY_PYTHON_PREFIX}/include/python${PY_VER}"
)
set(Python_Development_INCLUDE_DIRS ${Python_INCLUDE_DIRS}) # Often the same as Python_INCLUDE_DIRS for development



# --- Optional: Set other commonly used variables if needed ---
# For instance, if you need the site-packages directory
set(Python_SITELIB "${MY_PYTHON_PREFIX}/lib/python${PY_VER}/site-packages")

# Inform the user that Python was found via this custom module (useful for debugging)
message(STATUS "Found Python (custom FindPython.cmake):")
message(STATUS "  Interpreter: ${Python_EXECUTABLE}")
message(STATUS "  Libraries: ${Python_LIBRARIES}")
message(STATUS "  Includes: ${Python_INCLUDE_DIRS}")
message(STATUS "  Version: ${Python_VERSION_STRING}")

# Mark variables as advanced so they don't clutter the CMake GUI by default
mark_as_advanced(
    Python_EXECUTABLE
    Python_LIBRARIES
    Python_INCLUDE_DIRS
    Python_Development_LIBRARIES
    Python_Development_INCLUDE_DIRS
    Python_VERSION_MAJOR
    Python_VERSION_MINOR
    Python_VERSION_PATCH
    Python_VERSION_STRING
)


# Create an imported INTERFACE library target for Python development
# This makes Python::Python and Python::Module available for linking and includes
if (NOT TARGET Python::Python)
    add_library(Python::Python INTERFACE IMPORTED)
    set_target_properties(Python::Python PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${Python_INCLUDE_DIRS}"
        INTERFACE_LINK_LIBRARIES "${Python_LIBRARIES}"
    )
    message(STATUS "Created Python::Python INTERFACE target.")
endif()

# Create an alias target for Python::Module, pointing to Python::Python
# This is what packages like nanobind specifically check for.
# It ensures that even if they expect a specific 'Module' target,
# it points to the general Python development target.
if (NOT TARGET Python::Module)
    add_library(Python::Module ALIAS Python::Python)
    message(STATUS "Created Python::Module ALIAS target pointing to Python::Python.")
endif()

# Optional: Create an executable target for the interpreter
if (NOT TARGET Python::Interpreter)
    add_executable(Python::Interpreter IMPORTED)
    set_target_properties(Python::Interpreter PROPERTIES
        IMPORTED_LOCATION "${Python_EXECUTABLE}"
    )
    message(STATUS "Created Python::Interpreter IMPORTED executable target.")
endif()



# create python_add_library impl. 
# Python_add_library (<name> [STATIC | SHARED | MODULE [USE_SABI <version>] [WITH_SOABI]]
                    # <source1> [<source2> ...])

function(python_add_library name)
    cmake_parse_arguments(PYLIB "WITH_SOABI" "TYPE;USE_SABI" "SOURCES" ${ARGN})

    # Default type
    if(NOT PYLIB_TYPE)
        set(PYLIB_TYPE MODULE)
    endif()

    # Allow positional sources (anything not parsed as a keyword)
    if(NOT PYLIB_SOURCES)
        set(PYLIB_SOURCES ${PYLIB_UNPARSED_ARGUMENTS})
    endif()

    # Validate sources
    if(NOT PYLIB_SOURCES)
        message(FATAL_ERROR "No source files provided to python_add_library(${name})")
    endif()

    # Library type handling
    if(PYLIB_TYPE STREQUAL "MODULE")
        set(options MODULE)
    elseif(PYLIB_TYPE STREQUAL "SHARED")
        set(options SHARED)
    elseif(PYLIB_TYPE STREQUAL "STATIC")
        set(options STATIC)
    else()
        message(FATAL_ERROR "Invalid library type specified: ${PYLIB_TYPE}")
    endif()

    add_library(${name} ${options} ${PYLIB_SOURCES})
    target_include_directories(${name} PRIVATE ${Python_INCLUDE_DIRS})
    target_link_libraries(${name} PRIVATE ${Python_LIBRARIES})
endfunction()

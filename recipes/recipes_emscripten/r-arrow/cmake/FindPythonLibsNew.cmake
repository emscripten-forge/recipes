# - Find python libraries
# This module finds the libraries corresponding to the Python interpreter
# FindPythonInterp provides.
# This code sets the following variables:
#
#  PYTHONLIBS_FOUND           - have the Python libs been found
#  PYTHON_PREFIX              - path to the Python installation
#  PYTHON_LIBRARIES           - path to the python library
#  PYTHON_INCLUDE_DIRS        - path to where Python.h is found
#  PYTHON_MODULE_EXTENSION    - lib extension, e.g. '.so' or '.pyd'
#  PYTHON_MODULE_PREFIX       - lib name prefix: usually an empty string
#  PYTHON_SITE_PACKAGES       - path to installation site-packages
#  PYTHON_IS_DEBUG            - whether the Python interpreter is a debug build
#
# Thanks to talljimbo for the patch adding the 'LDVERSION' config
# variable usage.

set(PYTHON_INCLUDE_DIR      "$ENV{PREFIX}/include/python3.13")
set(PYTHON_LIBRARY          "$ENV{PREFIX}/lib/libpython3.13.a")
set(PYTHON_MODULE_EXTENSION ".so")
set(PYTHON_SITE_PACKAGES    "$ENV{PREFIX}/lib/python3.13/site-packages")
set(PYTHON_IS_DEBUG         "FALSE")
mark_as_advanced(PYTHON_LIBRARY PYTHON_INCLUDE_DIR)

# We use PYTHON_INCLUDE_DIR, PYTHON_LIBRARY and PYTHON_DEBUG_LIBRARY for the
# cache entries because they are meant to specify the location of a single
# library. We now set the variables listed by the documentation for this
# module.
set(PYTHON_INCLUDE_DIRS "${PYTHON_INCLUDE_DIR}")
set(PYTHON_LIBRARIES "${PYTHON_LIBRARY}")
if(NOT PYTHON_DEBUG_LIBRARY)
  set(PYTHON_DEBUG_LIBRARY "")
endif()
set(PYTHON_DEBUG_LIBRARIES "${PYTHON_DEBUG_LIBRARY}")

set(PYTHON_EXECUTABLE "$ENV{PREFIX}/bin/python")

set(PYTHONINTERP_FOUND TRUE)

set(PYTHONLIBS_FOUND TRUE)
set(PythonLibsNew_FOUND TRUE)

if(NOT PYTHON_MODULE_PREFIX)
  set(PYTHON_MODULE_PREFIX "")
endif()

function(PYTHON_ADD_MODULE _NAME )
  get_property(_TARGET_SUPPORTS_SHARED_LIBS
    GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS)
  option(PYTHON_ENABLE_MODULE_${_NAME} "Add module ${_NAME}" TRUE)
  option(PYTHON_MODULE_${_NAME}_BUILD_SHARED
    "Add module ${_NAME} shared" ${_TARGET_SUPPORTS_SHARED_LIBS})

  # Mark these options as advanced
  mark_as_advanced(PYTHON_ENABLE_MODULE_${_NAME}
    PYTHON_MODULE_${_NAME}_BUILD_SHARED)

  if(PYTHON_ENABLE_MODULE_${_NAME})
    if(PYTHON_MODULE_${_NAME}_BUILD_SHARED)
      set(PY_MODULE_TYPE MODULE)
    else()
      set(PY_MODULE_TYPE STATIC)
      set_property(GLOBAL  APPEND  PROPERTY  PY_STATIC_MODULES_LIST ${_NAME})
    endif()

    set_property(GLOBAL  APPEND  PROPERTY  PY_MODULES_LIST ${_NAME})
    add_library(${_NAME} ${PY_MODULE_TYPE} ${ARGN})
#    target_link_libraries(${_NAME} ${PYTHON_LIBRARIES})

    if(PYTHON_MODULE_${_NAME}_BUILD_SHARED)
      set_target_properties(${_NAME} PROPERTIES PREFIX "${PYTHON_MODULE_PREFIX}")
      if(WIN32 AND NOT CYGWIN)
        set_target_properties(${_NAME} PROPERTIES SUFFIX ".pyd")
      endif()
    endif()

  endif()
endfunction()
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

SET(PY_VERSION ${py_version})

set(PYTHON_INCLUDE_DIR      "$ENV{PREFIX}/include/python${PY_VERSION}")
set(PYTHON_LIBRARY          "$ENV{PREFIX}/lib/libpython${PY_VERSION}.a")
set(PYTHON_MODULE_EXTENSION ".so")
set(PYTHON_SITE_PACKAGES    "$ENV{PREFIX}/lib/python${PY_VERSION}/site-packages")
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



set(PYTHONLIBS_FOUND TRUE)
set(PythonLibsNew_FOUND TRUE)

if(NOT PYTHON_MODULE_PREFIX)
  set(PYTHON_MODULE_PREFIX "")
endif()
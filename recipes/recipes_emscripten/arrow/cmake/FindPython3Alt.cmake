# This module finds the libraries corresponding to the Python 3 interpreter
# and the NumPy package, and sets the following variables:
# - PYTHON_EXECUTABLE
# - PYTHON_INCLUDE_DIRS
# - PYTHON_LIBRARIES
# - PYTHON_OTHER_LIBS
# - NUMPY_INCLUDE_DIRS

if(Python3Alt_FOUND)
  return()
endif()

set(PYTHON_OTHER_LIBS)

find_package(PythonLibsNew)
find_package(NumPy)

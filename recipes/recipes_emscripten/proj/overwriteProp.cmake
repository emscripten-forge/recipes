set_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS TRUE) # does not need to be global :)
set(CMAKE_SHARED_LIBRARY_CREATE_C_FLAGS "-s SIDE_MODULE=1")
set(CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS "-s SIDE_MODULE=1")
set(CMAKE_STRIP FALSE)  # used by default in pybind11 on .so modules # only for needed when using pybind11

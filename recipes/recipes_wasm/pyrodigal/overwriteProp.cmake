set_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS TRUE)
set(CMAKE_SHARED_LIBRARY_CREATE_C_FLAGS "-s WASM_BIGINT -fwasm-exceptions")
set(CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS "-s WASM_BIGINT -fwasm-exceptions")
set(CMAKE_STRIP FALSE)  # used by default in pybind11 on .so modules
set(CMAKE_SHARED_MODULE_PREFIX "")  # avoid the Unix "lib" prefix on Cython modules

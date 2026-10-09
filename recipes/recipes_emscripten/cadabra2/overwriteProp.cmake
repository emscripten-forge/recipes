# Emscripten.cmake disables shared libraries; Python extension modules are
# built as wasm side modules instead.
set_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS TRUE)
set(CMAKE_SHARED_LIBRARY_CREATE_C_FLAGS "-sSIDE_MODULE=1")
set(CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS "-sSIDE_MODULE=1")
set(CMAKE_STRIP FALSE)  # pybind11 strips .so modules by default

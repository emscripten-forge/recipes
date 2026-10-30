set_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS TRUE)
set(CMAKE_SHARED_LIBRARY_CREATE_C_FLAGS "-s SIDE_MODULE=1")
set(CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS "-s SIDE_MODULE=1")
set(CMAKE_STRIP FALSE)
# setup.py runs plain cmake (not emcmake): the emsdk toolchain decides the
# pointer size before the -m64 from CFLAGS is in CMAKE_C_FLAGS, so on wasm64
# find_package(qdldl) would reject the 64bit libqdldl config.
if(CMAKE_C_FLAGS MATCHES "MEMORY64|-m64")
  set(CMAKE_SIZEOF_VOID_P 8)
endif()

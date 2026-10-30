# Use cpuinfo from the cpuinfo-static package instead of building (and
# installing) XNNPACK's own copy: XNNPACK only adds its bundled cpuinfo
# when no `cpuinfo` target exists yet. (CMAKE_PROJECT_INCLUDE runs for every
# project() call, also those of the bundled pthreadpool / FXdiv.)
if(NOT TARGET cpuinfo)
    add_library(cpuinfo STATIC IMPORTED GLOBAL)
    set_target_properties(cpuinfo PROPERTIES
        IMPORTED_LOCATION "${CMAKE_PREFIX_PATH}/lib/libcpuinfo.a"
        INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_PREFIX_PATH}/include")
endif()

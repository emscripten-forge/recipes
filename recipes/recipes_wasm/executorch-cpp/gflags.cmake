find_package(gflags CONFIG REQUIRED)
if(TARGET gflags AND NOT TARGET gflags::gflags)
    add_library(gflags::gflags ALIAS gflags)
endif()

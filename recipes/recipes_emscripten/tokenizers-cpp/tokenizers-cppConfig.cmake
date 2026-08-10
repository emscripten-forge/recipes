include(CMakeFindDependencyMacro)
find_dependency(sentencepiece REQUIRED)
find_dependency(msgpack-cxx REQUIRED)
include("${CMAKE_CURRENT_LIST_DIR}/tokenizers-cppTargets.cmake")

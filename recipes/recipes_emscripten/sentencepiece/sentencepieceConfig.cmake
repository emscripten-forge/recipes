include(CMakeFindDependencyMacro)
find_dependency(absl REQUIRED)
find_dependency(protobuf CONFIG REQUIRED)
include("${CMAKE_CURRENT_LIST_DIR}/sentencepieceTargets.cmake")

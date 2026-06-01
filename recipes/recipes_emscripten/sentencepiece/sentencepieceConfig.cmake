include(CMakeFindDependencyMacro)
find_dependency(absl REQUIRED)
include("${CMAKE_CURRENT_LIST_DIR}/sentencepieceTargets.cmake")

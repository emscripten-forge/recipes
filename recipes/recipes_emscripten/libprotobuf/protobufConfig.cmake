include(CMakeFindDependencyMacro)
include("${CMAKE_CURRENT_LIST_DIR}/protobufTargets.cmake")

get_filename_component(_protobuf_prefix "${CMAKE_CURRENT_LIST_FILE}" PATH)
get_filename_component(_protobuf_prefix "${_protobuf_prefix}" PATH)
get_filename_component(_protobuf_prefix "${_protobuf_prefix}" PATH)
get_filename_component(_protobuf_prefix "${_protobuf_prefix}" PATH)

set(protobuf_FOUND TRUE)
set(Protobuf_FOUND TRUE)
set(Protobuf_INCLUDE_DIR "${_protobuf_prefix}/include")
set(Protobuf_INCLUDE_DIRS "${_protobuf_prefix}/include")
set(Protobuf_LIBRARIES protobuf::libprotobuf)
set(Protobuf_LITE_LIBRARIES protobuf::libprotobuf-lite)

unset(_protobuf_prefix)

if(NOT TARGET tokenizers_cpp)
    add_library(tokenizers_cpp STATIC IMPORTED)
    set_target_properties(tokenizers_cpp PROPERTIES
        IMPORTED_LOCATION "${CMAKE_CURRENT_LIST_DIR}/../../../lib/libtokenizers_cpp.a"
        INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_CURRENT_LIST_DIR}/../../../include"
        INTERFACE_LINK_LIBRARIES "sentencepiece::sentencepiece;msgpack-cxx;${CMAKE_CURRENT_LIST_DIR}/../../../lib/libtokenizers_c.a"
    )
endif()

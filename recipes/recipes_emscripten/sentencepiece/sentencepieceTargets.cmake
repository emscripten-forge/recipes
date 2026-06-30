if(NOT TARGET sentencepiece::sentencepiece)
    add_library(sentencepiece::sentencepiece STATIC IMPORTED)
    set_target_properties(sentencepiece::sentencepiece PROPERTIES
        IMPORTED_LOCATION "${CMAKE_CURRENT_LIST_DIR}/../../libsentencepiece.a"
        INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_CURRENT_LIST_DIR}/../../../include"
        INTERFACE_LINK_LIBRARIES "absl::base;absl::flags;absl::flags_parse;absl::flat_hash_map;absl::flat_hash_set;absl::log;absl::random_random;absl::status;absl::statusor;absl::str_format;absl::strings;protobuf::libprotobuf"
    )
endif()

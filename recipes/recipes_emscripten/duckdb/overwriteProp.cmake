set_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS TRUE)
set(CMAKE_SHARED_LIBRARY_CREATE_C_FLAGS "-sSIDE_MODULE=1 -sWASM_BIGINT")
set(CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS "-sSIDE_MODULE=1 -sWASM_BIGINT")
set(CMAKE_STRIP FALSE)

# DuckDB links libduckdb_static.a twice to resolve circular dependencies
# between the core and extensions. Native linkers handle this but wasm-ld
# does not. Allow multiple definitions to work around this.
add_link_options("LINKER:--allow-multiple-definition")

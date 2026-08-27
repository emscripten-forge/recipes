# OpenSSL CMake config for conda environment

# Create imported target for libcrypto
add_library(OpenSSL::Crypto STATIC IMPORTED)
set_target_properties(OpenSSL::Crypto PROPERTIES
    IMPORTED_LOCATION "${CMAKE_CURRENT_LIST_DIR}/../../../lib/libcrypto.a"
    INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_CURRENT_LIST_DIR}/../../../include"
)

# Create imported target for libssl
add_library(OpenSSL::SSL STATIC IMPORTED)
set_target_properties(OpenSSL::SSL PROPERTIES
    IMPORTED_LOCATION "${CMAKE_CURRENT_LIST_DIR}/../../../lib/libssl.a"
    INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_CURRENT_LIST_DIR}/../../../include"
    INTERFACE_LINK_LIBRARIES "OpenSSL::Crypto"
)

# Set version information
set(OPENSSL_VERSION "@VERSION@")
set(OPENSSL_FOUND TRUE)

# Legacy variables for compatibility
set(OPENSSL_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/../../../include")
set(OPENSSL_CRYPTO_LIBRARY "${CMAKE_CURRENT_LIST_DIR}/../../../lib/libcrypto.a")
set(OPENSSL_SSL_LIBRARY "${CMAKE_CURRENT_LIST_DIR}/../../../lib/libssl.a")
set(OPENSSL_LIBRARIES "${OPENSSL_SSL_LIBRARY};${OPENSSL_CRYPTO_LIBRARY}")

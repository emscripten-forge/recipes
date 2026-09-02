#include <openssl/ssl.h>
#include <openssl/err.h>
#include <openssl/evp.h>
#include <openssl/sha.h>
#include <cstring>
#include <iostream>

// Test basic OpenSSL functionality
int main() {
    // Test 1: Check OpenSSL version
    std::cout << "OpenSSL version: " << OpenSSL_version(OPENSSL_VERSION) << std::endl;
    
    // Test 2: Test SHA256 hashing
    const char* test_string = "Hello, OpenSSL!";
    unsigned char hash[SHA256_DIGEST_LENGTH];
    
    SHA256(reinterpret_cast<const unsigned char*>(test_string), 
           std::strlen(test_string), hash);
    
    std::cout << "SHA256 hash computed successfully" << std::endl;
    
    // Test 3: Initialize SSL library
    SSL_library_init();
    OpenSSL_add_all_algorithms();
    SSL_load_error_strings();
    
    std::cout << "SSL library initialized successfully" << std::endl;
    
    // Test 4: Create SSL context
    const SSL_METHOD* method = TLS_client_method();
    SSL_CTX* ctx = SSL_CTX_new(method);
    
    if (!ctx) {
        std::cerr << "Failed to create SSL context" << std::endl;
        return 1;
    }
    
    std::cout << "SSL context created successfully" << std::endl;
    
    // Clean up
    SSL_CTX_free(ctx);
    EVP_cleanup();
    
    std::cout << "All tests passed!" << std::endl;
    return 0;
}

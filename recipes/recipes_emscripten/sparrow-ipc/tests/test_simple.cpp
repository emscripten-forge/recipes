#include <iostream>
#include <sparrow_ipc/config/sparrow_ipc_version.hpp>
#include <sparrow_ipc/compression.hpp>
#include <sparrow_ipc/serialize.hpp>
#include <sparrow_ipc/deserialize.hpp>

int main() {
    std::cout << "Testing sparrow-ipc library..." << std::endl;
    
    // Test version constants
    std::cout << "sparrow-ipc version: " 
              << sparrow_ipc::SPARROW_IPC_VERSION_MAJOR << "."
              << sparrow_ipc::SPARROW_IPC_VERSION_MINOR << "."
              << sparrow_ipc::SPARROW_IPC_VERSION_PATCH << std::endl;
    
    // Test compression types enum (header-only)
    sparrow_ipc::CompressionType lz4_type = sparrow_ipc::CompressionType::LZ4_FRAME;
    sparrow_ipc::CompressionType zstd_type = sparrow_ipc::CompressionType::ZSTD;
    
    std::cout << "Compression types available: LZ4_FRAME and ZSTD" << std::endl;
    std::cout << "LZ4_FRAME enum value: " << static_cast<int>(lz4_type) << std::endl;
    std::cout << "ZSTD enum value: " << static_cast<int>(zstd_type) << std::endl;
    
    std::cout << "\nSerialize and deserialize headers included successfully!" << std::endl;
    std::cout << "sparrow-ipc headers compile successfully!" << std::endl;
    std::cout << "All tests passed!" << std::endl;
    return 0;
}

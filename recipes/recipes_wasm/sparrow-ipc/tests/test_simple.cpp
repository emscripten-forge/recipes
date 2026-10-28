#include <iostream>
#include <sparrow_ipc/config/sparrow_ipc_version.hpp>
#include <sparrow_ipc/compression.hpp>
#include <sparrow_ipc/serialize.hpp>
#include <sparrow_ipc/deserialize.hpp>
#include <sparrow_ipc/memory_output_stream.hpp>
#include <sparrow_ipc/stream_file_serializer.hpp>
#include <sparrow_ipc/magic_values.hpp>

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

    // Create a simple record batch
    std::vector<std::string> names = {"int_col", "float_col"};

    // Create int32 array: [1, 2, 3, 4, 5]
    std::vector<int32_t> int_data = {1, 2, 3, 4, 5};
    sparrow::primitive_array<int32_t> int_array(std::move(int_data));

    // Create float array: [1.1, 2.2, 3.3, 4.4, 5.5]
    std::vector<float> float_data = {1.1f, 2.2f, 3.3f, 4.4f, 5.5f};
    sparrow::primitive_array<float> float_array(std::move(float_data));

    std::vector<sparrow::array> arrays;
    arrays.emplace_back(std::move(int_array));
    arrays.emplace_back(std::move(float_array));

    sparrow::record_batch batch(names, std::move(arrays));

    // Serialize using stream_file_serializer
    std::vector<uint8_t> file_data;
    sparrow_ipc::memory_output_stream mem_stream(file_data);
    
    {
        sparrow_ipc::stream_file_serializer serializer(mem_stream);
        serializer << batch << sparrow_ipc::end_file;
    }

    std::cout << "All tests passed!" << std::endl;
    return 0;
}

#include <snappy.h>
#include <cstring>
#include <cassert>
#include <iostream>
#include <string>

int main() {
    // Test data
    const std::string original = "Hello, Snappy! This is a test string for compression. "
                                 "Snappy is a fast compressor/decompressor developed by Google. "
                                 "It aims for very high speeds and reasonable compression ratios.";
    
    std::cout << "Original size: " << original.size() << " bytes\n";
    
    // Compression
    std::string compressed;
    snappy::Compress(original.data(), original.size(), &compressed);
    
    std::cout << "Compressed size: " << compressed.size() << " bytes\n";
    assert(compressed.size() > 0);
    assert(compressed.size() <= original.size()); // Compressed should not be larger for this data
    
    // Decompression
    std::string decompressed;
    bool result = snappy::Uncompress(compressed.data(), compressed.size(), &decompressed);
    
    assert(result == true);
    assert(decompressed == original);
    std::cout << "Decompression successful!\n";
    
    // Test GetUncompressedLength
    size_t uncompressed_length;
    result = snappy::GetUncompressedLength(compressed.data(), compressed.size(), &uncompressed_length);
    assert(result == true);
    assert(uncompressed_length == original.size());
    std::cout << "GetUncompressedLength: " << uncompressed_length << " bytes\n";
    
    // Test IsValidCompressedBuffer
    result = snappy::IsValidCompressedBuffer(compressed.data(), compressed.size());
    assert(result == true);
    std::cout << "IsValidCompressedBuffer: passed\n";
    
    std::cout << "All tests passed!\n";
    return 0;
}

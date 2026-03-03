#include <lz4.h>
#include <lz4hc.h>
#include <cstdio>
#include <cstring>
#include <cassert>

int main() {
    // Test data
    const char* original = "Hello, LZ4! This is a test string for compression.";
    const int original_size = strlen(original) + 1;
    
    // Compression
    const int max_compressed_size = LZ4_compressBound(original_size);
    char* compressed = new char[max_compressed_size];
    
    const int compressed_size = LZ4_compress_default(
        original, compressed, original_size, max_compressed_size
    );
    
    assert(compressed_size > 0);
    printf("Original size: %d bytes\n", original_size);
    printf("Compressed size: %d bytes\n", compressed_size);
    
    // Decompression
    char* decompressed = new char[original_size];
    const int decompressed_size = LZ4_decompress_safe(
        compressed, decompressed, compressed_size, original_size
    );
    
    assert(decompressed_size == original_size);
    assert(strcmp(original, decompressed) == 0);
    printf("Decompression successful!\n");
    
    // Test HC compression
    char* compressed_hc = new char[max_compressed_size];
    const int compressed_hc_size = LZ4_compress_HC(
        original, compressed_hc, original_size, max_compressed_size, LZ4HC_CLEVEL_DEFAULT
    );
    
    assert(compressed_hc_size > 0);
    printf("HC Compressed size: %d bytes\n", compressed_hc_size);
    
    // Cleanup
    delete[] compressed;
    delete[] decompressed;
    delete[] compressed_hc;
    
    printf("All tests passed!\n");
    return 0;
}

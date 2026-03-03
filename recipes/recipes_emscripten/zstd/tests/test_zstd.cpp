#include <zstd.h>
#include <iostream>
#include <cstring>
#include <vector>

int main() {
    // Test 1: Check zstd version
    unsigned version = ZSTD_versionNumber();
    std::cout << "Zstd version: " << ZSTD_versionString() << " (" << version << ")" << std::endl;
    
    // Test 2: Simple compression/decompression test
    const char* original = "Hello, Zstandard! This is a test of the compression library.";
    size_t originalSize = std::strlen(original) + 1;
    
    std::cout << "Original data: \"" << original << "\" (" << originalSize << " bytes)" << std::endl;
    
    // Compress
    size_t compressBound = ZSTD_compressBound(originalSize);
    std::vector<char> compressed(compressBound);
    
    size_t compressedSize = ZSTD_compress(
        compressed.data(), compressed.size(),
        original, originalSize,
        1  // compression level
    );
    
    if (ZSTD_isError(compressedSize)) {
        std::cerr << "Compression error: " << ZSTD_getErrorName(compressedSize) << std::endl;
        return 1;
    }
    
    std::cout << "Compressed size: " << compressedSize << " bytes" << std::endl;
    
    // Decompress
    unsigned long long decompressedSize = ZSTD_getFrameContentSize(compressed.data(), compressedSize);
    
    if (decompressedSize == ZSTD_CONTENTSIZE_ERROR) {
        std::cerr << "Not a valid zstd compressed frame" << std::endl;
        return 1;
    }
    
    if (decompressedSize == ZSTD_CONTENTSIZE_UNKNOWN) {
        std::cerr << "Original size unknown" << std::endl;
        return 1;
    }
    
    std::vector<char> decompressed(decompressedSize);
    
    size_t const dSize = ZSTD_decompress(
        decompressed.data(), decompressed.size(),
        compressed.data(), compressedSize
    );
    
    if (ZSTD_isError(dSize)) {
        std::cerr << "Decompression error: " << ZSTD_getErrorName(dSize) << std::endl;
        return 1;
    }
    
    std::cout << "Decompressed size: " << dSize << " bytes" << std::endl;
    
    // Verify decompressed data matches original
    if (std::strcmp(original, decompressed.data()) != 0) {
        std::cerr << "Decompressed data doesn't match original!" << std::endl;
        return 1;
    }
    
    std::cout << "Decompressed data matches original: \"" << decompressed.data() << "\"" << std::endl;
    
    // Test 3: Test compression context
    ZSTD_CCtx* cctx = ZSTD_createCCtx();
    if (!cctx) {
        std::cerr << "Failed to create compression context" << std::endl;
        return 1;
    }
    std::cout << "Compression context created successfully" << std::endl;
    ZSTD_freeCCtx(cctx);
    
    // Test 4: Test decompression context
    ZSTD_DCtx* dctx = ZSTD_createDCtx();
    if (!dctx) {
        std::cerr << "Failed to create decompression context" << std::endl;
        return 1;
    }
    std::cout << "Decompression context created successfully" << std::endl;
    ZSTD_freeDCtx(dctx);
    
    std::cout << "\nAll tests passed!" << std::endl;
    return 0;
}

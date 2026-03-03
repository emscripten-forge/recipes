#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <zlib.h>

#define CHUNK 16384

int test_compression() {
    const char* test_data = "Hello, World! This is a test string for zlib compression.";
    size_t test_data_len = strlen(test_data) + 1;
    
    // Compress
    unsigned char compressed[CHUNK];
    uLongf compressed_len = CHUNK;
    
    int ret = compress(compressed, &compressed_len, (const unsigned char*)test_data, test_data_len);
    if (ret != Z_OK) {
        printf("Compression failed with code: %d\n", ret);
        return 1;
    }
    
    printf("Original size: %zu, Compressed size: %lu\n", test_data_len, compressed_len);
    
    // Decompress
    unsigned char decompressed[CHUNK];
    uLongf decompressed_len = CHUNK;
    
    ret = uncompress(decompressed, &decompressed_len, compressed, compressed_len);
    if (ret != Z_OK) {
        printf("Decompression failed with code: %d\n", ret);
        return 1;
    }
    
    printf("Decompressed size: %lu\n", decompressed_len);
    
    // Verify
    if (strcmp((char*)decompressed, test_data) != 0) {
        printf("Decompressed data doesn't match original!\n");
        return 1;
    }
    
    printf("✓ Compression/decompression test passed\n");
    return 0;
}

int test_version() {
    const char* version = zlibVersion();
    printf("zlib version: %s\n", version);
    
    if (version == NULL || strlen(version) == 0) {
        printf("Failed to get zlib version\n");
        return 1;
    }
    
    printf("✓ Version test passed\n");
    return 0;
}

int test_crc32() {
    const char* test_data = "Test data for CRC32";
    uLong crc = crc32(0L, Z_NULL, 0);
    crc = crc32(crc, (const unsigned char*)test_data, strlen(test_data));
    
    printf("CRC32 of test data: 0x%08lx\n", crc);
    
    if (crc == 0) {
        printf("CRC32 calculation failed\n");
        return 1;
    }
    
    printf("✓ CRC32 test passed\n");
    return 0;
}

int main() {
    printf("=== zlib Test Suite ===\n\n");
    
    int ret = 0;
    
    ret |= test_version();
    ret |= test_compression();
    ret |= test_crc32();
    
    if (ret == 0) {
        printf("\n=== All tests passed! ===\n");
    } else {
        printf("\n=== Some tests failed ===\n");
    }
    
    return ret;
}

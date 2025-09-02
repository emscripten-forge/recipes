import zstandard as zstd

# Test basic compression/decompression
data = b"hello world" * 100
compressor = zstd.ZstdCompressor()
compressed = compressor.compress(data)

decompressor = zstd.ZstdDecompressor()
decompressed = decompressor.decompress(compressed)

assert decompressed == data
print("zstandard compression/decompression test passed")
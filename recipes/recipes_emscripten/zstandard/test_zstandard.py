import io
import struct


def test_zstandard_compression_and_decompression():
    import zstandard as zstd

    data = b"foo"
    compress = zstd.ZstdCompressor(
        write_checksum=True, write_content_size=True
    ).compress
    decompress = zstd.ZstdDecompressor().decompress

    assert decompress(compress(data)) == data


def test_zstandard_compression_and_decompression_with_level():
    import zstandard as zstd

    data = b"foo"
    compress = zstd.ZstdCompressor(
        level=1, write_checksum=True, write_content_size=True
    ).compress
    decompress = zstd.ZstdDecompressor().decompress

    assert decompress(compress(data)) == data


def test_compress_empty():
    import zstandard as zstd

    cctx = zstd.ZstdCompressor(level=1, write_content_size=False)

    result = cctx.compress(b"")
    assert result == b"\x28\xb5\x2f\xfd\x00\x00\x01\x00\x00"

    params = zstd.get_frame_parameters(result)
    assert params.window_size == 1024
    assert params.dict_id == 0
    assert params.has_checksum is False

    cctx = zstd.ZstdCompressor()
    result = cctx.compress(b"")
    assert result == b"\x28\xb5\x2f\xfd\x20\x00\x01\x00\x00"
    params = zstd.get_frame_parameters(result)
    assert params.content_size == 0


def test_compress_large():
    import zstandard as zstd

    chunks = []
    for i in range(255):
        chunks.append(struct.Struct(">B").pack(i) * 16384)

    data = b"".join(chunks)
    cctx = zstd.ZstdCompressor(level=3)
    compressed = cctx.compress(data)
    assert len(compressed) < len(data)

    dctx = zstd.ZstdDecompressor()
    assert dctx.decompress(compressed, max_output_size=len(data)) == data


def test_stream_roundtrip():
    import zstandard as zstd

    source = b"zstandard stream " * 4096
    buffer = io.BytesIO()
    with zstd.ZstdCompressor(level=5).stream_writer(buffer, closefd=False) as w:
        w.write(source)

    buffer.seek(0)
    with zstd.ZstdDecompressor().stream_reader(buffer) as reader:
        assert reader.read() == source


def test_compression_is_deterministic():
    import zstandard as zstd

    data = b"deterministic input " * 100
    a = zstd.ZstdCompressor(level=3).compress(data)
    b = zstd.ZstdCompressor(level=3).compress(data)
    assert a == b

from PIL import Image

def test_pyheif():
    import pyheif

    heif_file = pyheif.read("test_astronaut.heic")

    assert heif_file.mode == 'RGB'
    assert heif_file.size == (500, 292)
    assert heif_file.stride == 1504

    image = Image.frombytes(
        heif_file.mode,
        heif_file.size,
        heif_file.data,
        "raw",
        heif_file.mode,
        heif_file.stride
    )

    assert image.width == 500

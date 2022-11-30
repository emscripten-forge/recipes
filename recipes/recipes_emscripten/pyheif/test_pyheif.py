import pathlib

def test_pyheif():
    import pyheif

    TEST_IMAGE = pathlib.Path(__file__).parent / "test_astronaut.heic"
    print("Image path: ", TEST_IMAGE)

    heif_file = pyheif.read(TEST_IMAGE)

    assert heif_file.mode == 'RGB'
    assert heif_file.size == (500, 292)
    assert heif_file.stride == 1504

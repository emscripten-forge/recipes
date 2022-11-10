def test_pyheif():
    import pyheif

    heif_file = pyheif.read("test_astronaut.heic")

    assert heif_file.mode == 'RGB'
    assert heif_file.size == (500, 292)
    assert heif_file.stride == 1504

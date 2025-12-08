def test_import_pillow_heif():
    import pillow_heif


def test_pillow_heif_basic():
    import pillow_heif
    from PIL import Image

    # Register HEIF opener with Pillow
    pillow_heif.register_heif_opener()

    # # Check that the plugin is registered
    assert 'HEIF' in Image.EXTENSION.values()
    assert '.heic' in Image.EXTENSION
    assert '.heif' in Image.EXTENSION
def test_import_simpleitk():
    import SimpleITK as sitk
    # Basic sanity check
    img = sitk.Image(10, 10, sitk.sitkUInt8)
    assert img.GetWidth() == 10
    assert img.GetHeight() == 10

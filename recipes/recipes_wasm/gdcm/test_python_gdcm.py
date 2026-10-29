import numpy as np


def test_version():
    import gdcm

    assert gdcm.Version.GetVersion().startswith("3.")


def _write_uncompressed(path, pixels):
    from pydicom.dataset import Dataset, FileMetaDataset
    from pydicom.uid import ExplicitVRLittleEndian, generate_uid

    meta = FileMetaDataset()
    meta.MediaStorageSOPClassUID = "1.2.840.10008.5.1.4.1.1.7"
    meta.MediaStorageSOPInstanceUID = generate_uid()
    meta.TransferSyntaxUID = ExplicitVRLittleEndian

    ds = Dataset()
    ds.file_meta = meta
    ds.SOPClassUID = meta.MediaStorageSOPClassUID
    ds.SOPInstanceUID = meta.MediaStorageSOPInstanceUID
    ds.PatientName = "Wasm^Test"
    ds.Rows, ds.Columns = pixels.shape
    ds.SamplesPerPixel = 1
    ds.PhotometricInterpretation = "MONOCHROME2"
    ds.BitsAllocated = 16
    ds.BitsStored = 16
    ds.HighBit = 15
    ds.PixelRepresentation = 0
    ds.PixelData = pixels.tobytes()
    ds.save_as(path, enforce_file_format=True)


def test_read_with_gdcm(tmp_path):
    import gdcm

    pixels = (np.arange(16 * 20) * 7).astype(np.uint16).reshape(16, 20)
    path = str(tmp_path / "plain.dcm")
    _write_uncompressed(path, pixels)

    reader = gdcm.ImageReader()
    reader.SetFileName(path)
    assert reader.Read()
    image = reader.GetImage()
    assert image.GetDimension(0) == 20
    assert image.GetDimension(1) == 16


def test_jpegls_roundtrip_via_pydicom(tmp_path):
    """compress with gdcm, decode with pydicom's gdcm pixel data plugin"""
    import gdcm
    import pydicom

    pixels = (np.arange(16 * 20) * 7).astype(np.uint16).reshape(16, 20)
    src = str(tmp_path / "plain.dcm")
    dst = str(tmp_path / "jpegls.dcm")
    _write_uncompressed(src, pixels)

    reader = gdcm.ImageReader()
    reader.SetFileName(src)
    assert reader.Read()

    change = gdcm.ImageChangeTransferSyntax()
    change.SetTransferSyntax(gdcm.TransferSyntax(gdcm.TransferSyntax.JPEGLSLossless))
    change.SetInput(reader.GetImage())
    assert change.Change()

    writer = gdcm.ImageWriter()
    writer.SetFileName(dst)
    writer.SetFile(reader.GetFile())
    writer.SetImage(change.GetOutput())
    assert writer.Write()

    ds = pydicom.dcmread(dst)
    assert ds.file_meta.TransferSyntaxUID == "1.2.840.10008.1.2.4.80"
    np.testing.assert_array_equal(ds.pixel_array, pixels)

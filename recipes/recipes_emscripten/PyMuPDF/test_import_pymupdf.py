def test_import_pymupdf():
    import pymupdf
    import fitz
    
    # Test basic functionality
    doc = pymupdf.open()
    assert doc is not None
    
    # Test that fitz and pymupdf are the same module
    assert pymupdf is fitz
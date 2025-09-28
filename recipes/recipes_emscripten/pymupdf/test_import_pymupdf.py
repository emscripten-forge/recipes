def test_import_pymupdf():
    """Test importing PyMuPDF package."""
    import pymupdf
    import fitz
    
    # Basic functionality test
    doc = pymupdf.open()  # Create empty document
    page = doc.new_page()
    assert page is not None
    doc.close()
    
    # Test fitz alias works
    doc2 = fitz.open()
    page2 = doc2.new_page()
    assert page2 is not None
    doc2.close()
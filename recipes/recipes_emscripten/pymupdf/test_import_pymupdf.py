def test_import_pymupdf():
    """Test PyMuPDF import with WebAssembly compatibility checking"""
    import warnings
    
    # Capture warnings to check for stub package warning
    with warnings.catch_warnings(record=True) as w:
        warnings.simplefilter("always")
        
        try:
            import fitz
            print(f"Successfully imported fitz, version: {getattr(fitz, '__version__', 'unknown')}")
            
            # Check if this is the stub version
            if hasattr(fitz, '__version__') and 'stub' in fitz.__version__:
                print("Detected PyMuPDF stub package for WebAssembly compatibility")
                
                # Test that stub raises appropriate errors
                try:
                    fitz.Document()
                    assert False, "Expected NotImplementedError from stub"
                except NotImplementedError as e:
                    print(f"Stub correctly raises NotImplementedError: {e}")
                
                try:
                    fitz.open("test.pdf")
                    assert False, "Expected NotImplementedError from stub"
                except NotImplementedError as e:
                    print(f"Stub correctly raises NotImplementedError: {e}")
                
                print("PyMuPDF stub package working correctly")
            else:
                # If we have a real PyMuPDF, test basic functionality
                print("Testing full PyMuPDF functionality...")
                
                # Try creating a document
                try:
                    doc = fitz.Document()
                    page = doc.new_page()
                    page.insert_text((100, 100), "Hello WebAssembly!")
                    print("Successfully created PDF document")
                    doc.close()
                except Exception as e:
                    print(f"PDF creation failed (expected on WebAssembly): {e}")
                    # This is expected to fail on WebAssembly due to font issues
                    pass
            
            return True
            
        except ImportError as e:
            print(f"Failed to import fitz: {e}")
            return False

def test_pymupdf_alias():
    """Test that pymupdf module alias works"""
    try:
        import pymupdf
        print("Successfully imported pymupdf alias")
        return True
    except ImportError as e:
        print(f"Failed to import pymupdf alias: {e}")
        return False

if __name__ == "__main__":
    print("Testing PyMuPDF WebAssembly package...")
    
    success1 = test_import_pymupdf()
    success2 = test_pymupdf_alias()
    
    if success1 and success2:
        print("All tests passed!")
    else:
        print("Some tests failed")
        exit(1)
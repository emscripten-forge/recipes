#!/usr/bin/env python
"""
Test sparseqr import
"""

def test_sparseqr_import():
    """Test that sparseqr can be imported"""
    try:
        import sparseqr
        print("✓ sparseqr imported successfully")
        
        # Test basic attributes exist
        assert hasattr(sparseqr, 'qr'), "sparseqr.qr function should exist"
        assert hasattr(sparseqr, 'solve'), "sparseqr.solve function should exist"
        print("✓ sparseqr main functions are available")
        
    except ImportError as e:
        print(f"✗ Failed to import sparseqr: {e}")
        raise
    except Exception as e:
        print(f"✗ Error testing sparseqr: {e}")
        raise

if __name__ == "__main__":
    test_sparseqr_import()
    print("All tests passed!")
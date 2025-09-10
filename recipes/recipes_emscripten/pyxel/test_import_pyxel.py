def test_import_pyxel():
    """Test that pyxel can be imported successfully."""
    import pyxel
    print("pyxel import successful")


def test_pyxel_version():
    """Test that pyxel version is accessible."""
    import pyxel
    print(f"pyxel version: {pyxel.__version__}")


def test_pyxel_basic_attributes():
    """Test that basic pyxel attributes are available."""
    import pyxel
    
    # Try to access some basic pyxel attributes
    assert hasattr(pyxel, 'init'), "pyxel.init not found"
    assert hasattr(pyxel, 'run'), "pyxel.run not found" 
    assert hasattr(pyxel, 'cls'), "pyxel.cls not found"
    
    print("All basic pyxel imports and attributes are available")
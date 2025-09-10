#!/usr/bin/env python

try:
    import pyxel
    print("pyxel import successful")
    
    # Test basic functionality
    print(f"pyxel version: {pyxel.__version__}")
    
    # Try to access some basic pyxel attributes
    assert hasattr(pyxel, 'init'), "pyxel.init not found"
    assert hasattr(pyxel, 'run'), "pyxel.run not found"
    assert hasattr(pyxel, 'cls'), "pyxel.cls not found"
    
    print("All basic pyxel imports and attributes are available")
    
except ImportError as e:
    print(f"Failed to import pyxel: {e}")
    raise
except Exception as e:
    print(f"Error during pyxel testing: {e}")
    raise
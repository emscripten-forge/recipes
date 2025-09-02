#!/usr/bin/env python

try:
    import cv2
    print("Successfully imported cv2")
    print(f"OpenCV version: {cv2.__version__}")
    
    # Test basic functionality - create a simple image
    import numpy as np
    img = np.zeros((100, 100, 3), dtype=np.uint8)
    print("Successfully created a simple image array")
    
    # Test basic OpenCV operation
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    print("Successfully performed color conversion")
    
    print("Basic cv2 functionality test passed!")
    
except ImportError as e:
    print(f"Failed to import cv2: {e}")
    exit(1)
except Exception as e:
    print(f"Error in cv2 basic functionality: {e}")
    exit(1)
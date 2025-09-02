# Basic import test for fiona
# Note: Full functionality requires GDAL which is not yet available in emscripten-forge

try:
    import fiona
    print("Fiona import successful")
    print("Fiona version:", fiona.__version__)
    
    # Test basic attributes that don't require GDAL
    print("Fiona module loaded successfully")
    
    # This will likely fail without GDAL, but we can test import structure
    try:
        # Test basic functionality - check supported drivers (if GDAL is available)
        print("Supported drivers:")
        for driver in fiona.supported_drivers:
            print(f"  {driver}")
    except Exception as e:
        print(f"Driver listing failed (expected without GDAL): {e}")
    
    print("Fiona import test completed!")
    
except ImportError as e:
    print(f"Fiona import failed: {e}")
    # This is expected until GDAL is available
    exit(1)
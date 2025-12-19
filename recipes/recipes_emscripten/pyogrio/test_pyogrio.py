import os
import pytest


def test_pyogrio():
    # Set GDAL_DATA environment variable before importing pyogrio
    # pyogrio initializes GDAL data on import, so we need to set this first
    import sys
    
    # Try to find where GDAL data files are actually installed
    # In conda environments, they're typically in $PREFIX/share/gdal
    # Check multiple possible locations
    possible_paths = [
        "/share/gdal",  # Absolute path that appeared in error
        f"{sys.prefix}/share/gdal",  # Relative to Python prefix
    ]
    
    # Also check if PREFIX environment variable is set (common in conda)
    if 'PREFIX' in os.environ:
        possible_paths.insert(0, f"{os.environ['PREFIX']}/share/gdal")
    
    # Find the first path that exists and has content
    gdal_data_path = None
    for path in possible_paths:
        if os.path.exists(path) and os.path.isdir(path):
            try:
                # Check if directory has files (not just empty)
                if os.listdir(path):
                    gdal_data_path = path
                    break
            except (OSError, PermissionError):
                continue
    
    # Set GDAL_DATA if we found a valid path
    # Even if empty, setting it might help pyogrio's initialization
    if gdal_data_path:
        os.environ['GDAL_DATA'] = gdal_data_path
    elif possible_paths:
        # Set to the most likely location even if we can't verify it
        os.environ['GDAL_DATA'] = possible_paths[0]
    
    # Now import pyogrio - it will try to initialize GDAL data
    import pyogrio


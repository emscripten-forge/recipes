import pytest

def test_import_obspy():
    import  obspy

def test_obspy_core_functionality():  
    import obspy  
    # Test basic obspy functionality  
    from obspy import UTCDateTime  
    time = UTCDateTime("2023-01-01T00:00:00")  
    assert time.year == 2023

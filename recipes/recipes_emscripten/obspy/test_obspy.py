import pytest

def test_import_obspy():
    import  obspy

def test_obspy_core_functionality():  
    import obspy  
    # Test basic obspy functionality  
    from obspy import UTCDateTime  
    time = UTCDateTime("2023-01-01T00:00:00")  
    assert time.year == 2023

@pytest.mark.skip(reason="failing with <Protocol not available>")
# A possible reason is that IRIS doesn't provide an https websocket
# endpoint here.
def test_obspy_fdsn():
    from obspy.clients.fdsn import Client
    from obspy import UTCDateTime
    client = Client("IRIS", _discover_services=False)
    t1 = UTCDateTime("2010-02-27T06:30:00.000")
    t2 = t1 + 5
    st = client.get_waveforms("IU", "ANMO", "00", "LHZ", t1, t2)

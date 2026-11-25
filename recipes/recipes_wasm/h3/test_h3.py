def test_h3():
    import h3

    assert h3.latlng_to_cell(0, 0, 0) == "8075fffffffffff"
    assert h3.latlng_to_cell(0, 0, 1) == "81757ffffffffff"
    assert h3.latlng_to_cell(0, 0, 2) == "82754ffffffffff"
    assert h3.latlng_to_cell(10, 0, 2) == "82599ffffffffff"

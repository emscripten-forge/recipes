def test_import_cf_units():
    import cf_units
    cf_units.Unit("m").convert(1000,  "km")

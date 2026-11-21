def test_add_tenor():
    import datetime

    import rateslib as rl

    start_date = datetime.datetime(2024, 10, 29)
    end_date = datetime.datetime(2024, 10, 31)

    test_date = rl.add_tenor(start_date, "2b", "F", "nyc")

    assert end_date == test_date

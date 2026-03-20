def test_import_fiona():
    import fiona


def test_fiona_env():
    import fiona
    from fiona.env import Env

    # Basic context manager test (does not require filesystem)
    with Env():
        assert True


# def test_supported_drivers():
#     import fiona

#     drivers = fiona.supported_drivers
#     assert isinstance(drivers, dict)
def test_asyncpg_native_modules():
    # Smoke test: the Cython-compiled extension modules must import.
    # The end-to-end tests need a live PostgreSQL server and are not run here.
    from asyncpg.pgproto import pgproto
    from asyncpg.protocol import protocol, record

    assert pgproto is not None
    assert protocol is not None
    assert record is not None

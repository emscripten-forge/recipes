def test_snappy_manifolds():
    import snappy_manifolds

    assert snappy_manifolds.version() == '1.4'


def test_snappy_manifolds_databases():
    import snappy_manifolds

    # get_tables() needs SnapPy's ManifoldTable class, but get_DT_tables()
    # is self-contained and opens two of the SQLite databases, so it checks
    # that the data files were actually packaged and are readable.
    tables = snappy_manifolds.get_DT_tables()
    assert len(tables) == 2
    assert all(len(table) > 0 for table in tables)

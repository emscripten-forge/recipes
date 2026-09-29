import os
import sqlite3


def test_import_snappy_manifolds():
    import snappy_manifolds

    assert snappy_manifolds.version() == '1.4'


def test_census_databases_are_installed():
    import snappy_manifolds

    path = snappy_manifolds.manifolds_path
    assert os.path.isdir(path)
    for name in ['manifolds.sqlite', 'more_manifolds.sqlite',
                 'platonic_manifolds.sqlite', 'ribbon_links.sqlite']:
        assert os.path.isfile(os.path.join(path, name)), name


def test_census_is_queryable():
    import snappy_manifolds

    db = os.path.join(snappy_manifolds.manifolds_path, 'manifolds.sqlite')
    connection = sqlite3.connect(db)
    try:
        rows = list(connection.execute(
            'select name from orientable_cusped_view where name=?', ('m004',)))
    finally:
        connection.close()
    assert rows == [('m004',)]


def test_dt_tables():
    import snappy_manifolds

    tables = snappy_manifolds.get_DT_tables()
    assert len(tables) > 0

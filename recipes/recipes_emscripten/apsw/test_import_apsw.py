def test_import_apsw():
    import apsw
    # Test basic functionality
    connection = apsw.Connection(":memory:")
    cursor = connection.cursor()
    cursor.execute("SELECT 1")
    assert cursor.fetchall() == [(1,)]
    connection.close()
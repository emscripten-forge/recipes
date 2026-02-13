def test_import_duckdb():
    import duckdb
    # Test basic functionality
    conn = duckdb.connect(':memory:')
    result = conn.execute("SELECT 42 as answer").fetchone()
    assert result[0] == 42
    conn.close()

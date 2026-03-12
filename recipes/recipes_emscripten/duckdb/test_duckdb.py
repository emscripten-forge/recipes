import duckdb


def test_import():
    assert duckdb is not None


def test_basic_query():
    con = duckdb.connect()
    result = con.execute("SELECT 42 AS answer").fetchall()
    assert result == [(42,)]


def test_create_table():
    con = duckdb.connect()
    con.execute("CREATE TABLE t (x INTEGER, y VARCHAR)")
    con.execute("INSERT INTO t VALUES (1, 'hello'), (2, 'world')")
    result = con.execute("SELECT * FROM t ORDER BY x").fetchall()
    assert result == [(1, "hello"), (2, "world")]


def test_aggregation():
    con = duckdb.connect()
    con.execute("CREATE TABLE nums AS SELECT * FROM range(10) t(i)")
    result = con.execute("SELECT SUM(i), COUNT(*) FROM nums").fetchone()
    assert result == (45, 10)

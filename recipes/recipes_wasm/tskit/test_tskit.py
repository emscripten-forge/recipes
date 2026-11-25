import os
import tempfile


def _simple_tree_sequence():
    import tskit

    tc = tskit.TableCollection(2)
    tc.nodes.add_row(flags=tskit.NODE_IS_SAMPLE, time=0)
    tc.nodes.add_row(flags=tskit.NODE_IS_SAMPLE, time=0)
    tc.nodes.add_row(time=1)
    tc.edges.add_row(left=0, right=2, parent=2, child=0)
    tc.edges.add_row(left=0, right=2, parent=2, child=1)
    tc.sort()
    return tc.tree_sequence()


def test_import_tskit():
    import tskit

    assert isinstance(tskit.__version__, str)


def test_table_collection_and_tree_sequence():
    import tskit

    tc = tskit.TableCollection(2)
    assert tc.sequence_length == 2
    tc.nodes.add_row(flags=tskit.NODE_IS_SAMPLE)
    tc.nodes.add_row(time=1)
    tc.edges.add_row(left=0, right=1, parent=1, child=0)
    tc.edges.add_row(left=1, right=2, parent=1, child=0)
    ts = tc.tree_sequence()
    assert ts.num_nodes == 2
    assert ts.num_samples == 1


def test_tree_traversal():
    ts = _simple_tree_sequence()
    tree = ts.first()
    assert tree.num_roots == 1
    assert sorted(tree.leaves(2)) == [0, 1]
    assert tree.mrca(0, 1) == 2


def test_save_and_load_roundtrip():
    import tskit

    ts = _simple_tree_sequence()
    with tempfile.TemporaryDirectory() as tmpdir:
        path = os.path.join(tmpdir, "test.trees")
        ts.dump(path)
        ts2 = tskit.load(path)
    ts.tables.assert_equals(ts2.tables)


def test_metadata_schema():
    import tskit

    schema = tskit.MetadataSchema({"codec": "json"})
    assert schema.schema["codec"] == "json"

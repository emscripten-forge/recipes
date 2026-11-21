import os
import tempfile


def test_import_msprime():
    import msprime

    assert isinstance(msprime.__version__, str)


def test_simulate_dump_load_roundtrip():
    import msprime
    import tskit

    ts = msprime.sim_ancestry(10, random_seed=42)
    with tempfile.TemporaryDirectory() as tmpdir:
        path = os.path.join(tmpdir, "msprime.trees")
        ts.dump(path)
        ts_loaded = tskit.load(path)
    ts_same = msprime.sim_ancestry(10, random_seed=42)
    ts_loaded.tables.assert_equals(ts_same.tables, ignore_provenance=True)


def test_seeded_simulation_is_reproducible():
    import msprime

    ts1 = msprime.sim_ancestry(5, sequence_length=1e5, recombination_rate=1e-8, random_seed=7)
    ts2 = msprime.sim_ancestry(5, sequence_length=1e5, recombination_rate=1e-8, random_seed=7)
    assert ts1.num_trees == ts2.num_trees
    assert ts1.num_edges == ts2.num_edges
    assert ts1.num_samples == 10


def test_sim_mutations():
    import msprime

    ts = msprime.sim_ancestry(5, sequence_length=1e4, population_size=1000, random_seed=3)
    mts = msprime.sim_mutations(ts, rate=1e-6, random_seed=3)
    assert mts.num_sites > 0
    assert mts.num_mutations >= mts.num_sites
    assert mts.num_samples == 10

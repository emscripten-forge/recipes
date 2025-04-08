def test_import():
    import h5py
    import h5py._conv
    import h5py._errors
    import h5py._objects
    import h5py._proxy
    import h5py.defs
    import h5py.h5
    import h5py.h5a
    import h5py.h5d
    import h5py.h5f
    import h5py.h5fd
    import h5py.h5g
    import h5py.h5i
    import h5py.h5l
    import h5py.h5o
    import h5py.h5p
    import h5py.h5r
    import h5py.h5s
    import h5py.h5t
    import h5py.h5z
    import h5py.utils

def test_usage():
    import h5py

    with h5py.File("mytestfile.hdf5", "a") as f:
        dset = f.create_dataset("mydataset", (100,), dtype="i")
        grp = f.create_group("subgroup")
        dset2 = grp.create_dataset("another_dataset", (50,), dtype="f")

        assert f.name == "/"
        assert dset.name == "/mydataset"
        assert dset2.name == "/subgroup/another_dataset"

    f = h5py.File("mytestfile.hdf5", "r")
    assert sorted(list(f.keys())) == ["mydataset", "subgroup"]
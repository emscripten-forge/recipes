import numpy as np
import netCDF4
from netCDF4 import Dataset


def test_versions():
    print("netCDF4:", netCDF4.__version__)
    print("libnetcdf:", netCDF4.__netcdf4libversion__)
    print("libhdf5:", netCDF4.__hdf5libversion__)


def test_netcdf3_write_read(tmp_path):
    path = str(tmp_path / "c.nc")
    with Dataset(path, "w", format="NETCDF3_CLASSIC") as ds:
        ds.createDimension("x", 4)
        v = ds.createVariable("temp", "f8", ("x",))
        v[:] = np.arange(4.0)
    with Dataset(path, "r") as ds:
        assert ds.variables["temp"].shape == (4,)


def test_netcdf4_roundtrip(tmp_path):
    """End-to-end netcdf-4 round-trip: dim + variable + attribute."""
    path = str(tmp_path / "v.nc")
    with Dataset(path, "w", format="NETCDF4") as ds:
        ds.title = "hello"
        ds.createDimension("x", 4)
        v = ds.createVariable("temp", "f8", ("x",))
        v[:] = np.arange(4.0)
    with Dataset(path, "r") as ds:
        assert ds.title == "hello"
        assert "x" in ds.dimensions
        np.testing.assert_array_equal(ds.variables["temp"][:], np.arange(4.0))

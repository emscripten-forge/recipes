def test_netcdf4():
  from netCDF4 import Dataset
  rootgrp = Dataset("test.nc", "w", format="NETCDF4")
  rootgrp.data_model == "NETCDF4"
  rootgrp.close()



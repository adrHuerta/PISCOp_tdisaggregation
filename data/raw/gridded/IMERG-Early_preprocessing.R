reticulate::use_virtualenv("/home/adrian/PycharmProjects/hourly_PISCOp/venv/", required = TRUE)
reticulate::repl_python()

import xarray as xr
import numpy as np
import glob
import pandas as pd
import rioxarray
from geopandas import read_file as gpd_read_file

shp_Peru = gpd_read_file('./data/others/Departamentos.shp')
PISCOp_grid = xr.open_dataset("./data/others/PISCOp_grid_mask.nc").p
PISCOp_grid.values[~np.isnan(PISCOp_grid.values)] = 1

files_early = sorted(glob.glob("./data/raw/gridded/IMERG-Early/*.nc"))

for i_year in files_early:
  i_year_nc = xr.open_dataset(i_year)
  i_year_str = i_year.split("/")[7].split(".")[0]
  i_time_range = pd.date_range(start = i_year_str + "-01-01 00:00:00", periods = len(i_year_nc.z), freq = "H")
  
  new_i_year_nc = []
  for i_time in range(len(i_year_nc.z)):
    
    to_compute = i_year_nc.isel(z=i_time)
    to_save = to_compute.assign_coords(time=i_time_range[i_time])
    to_save = to_save.reindex_like(PISCOp_grid, method="nearest").variable
    to_save = to_save.where((to_save >= 0) | to_save.isnull(), 0)
    to_save = to_save.where(PISCOp_grid == True)
    to_save = (to_save + 0).to_dataset(name = "p")
  
  new_i_year_nc.append(to_save)
  encoding = {v: {'zlib': True, 'complevel': 5} for v in ["p"]}
  gpmimerg_early = xr.concat(new_i_year_nc, dim="time")
  gpmimerg_early["time"] = pd.to_datetime(gpmimerg_early.time.values) - pd.Timedelta(hours=5) # UTC to local time
  gpmimerg_early["time"] = pd.to_datetime(gpmimerg_early.time.values).shift(periods=-8, freq="H")  # 7pm-7am daily sum
  gpmimerg_early.to_netcdf("./data/processed/gridded/IMERG-Early/" + i_year_str + "_imerg_early_p.nc", encoding=encoding, engine='netcdf4')
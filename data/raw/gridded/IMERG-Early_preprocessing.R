reticulate::use_virtualenv("/home/waldo/PycharmProjects/forR/venv/", required = TRUE)
reticulate::repl_python()

import xarray as xr
import datetime
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
  i_year_str = i_year.split("/")[5].split(".")[0]
  i_time_range = pd.date_range(start = i_year_str + "-01-01 00:00:00", periods = len(i_year_nc.z), freq = "H")
  
  new_i_year_nc = []
  for i_time in range(len(i_year_nc.z)):
    to_compute = i_year_nc.isel(z=i_time)
    to_save = to_compute.assign_coords(time=i_time_range[i_time])
    to_save = to_save.reindex({"latitude":PISCOp_grid.latitude.values, "longitude":PISCOp_grid.longitude.values}, method="nearest").p
    to_save = to_save.where((to_save >= 0) | to_save.isnull())
    to_save = to_save.rio.write_nodata(np.nan)
    to_save = to_save.rio.write_crs("EPSG:3857")
    to_save = to_save.rio.interpolate_na(method="nearest")
    to_save = to_save.drop("crs")
    to_save = to_save.where(PISCOp_grid == True)
    to_save = to_save.astype("float32")
    to_save = np.round(to_save, 1)
    to_save = (to_save + 0).to_dataset(name = "p")
    new_i_year_nc.append(to_save)
  
  encoding = {v: {'zlib': True, 'complevel': 5} for v in ["p"]}
  gpmimerg_early = xr.concat(new_i_year_nc, dim="time")
  gpmimerg_early["time"] = pd.to_datetime(gpmimerg_early.time.values) - pd.Timedelta(hours=5) # UTC to local time
  gpmimerg_early["time"] = pd.to_datetime(gpmimerg_early.time.values).shift(periods=-8, freq="H")  # 7pm-7am daily sum
  gpmimerg_early.to_netcdf("./data/processed/gridded/IMERG-Early/" + i_year_str + "_imerg_early_p.nc", encoding=encoding, engine='netcdf4')

#·····································#

path_netcdf_in = "./data/processed/gridded/IMERG-Early/"
path_netcdf_out = "./data/processed/gridded/IMERG-Early/"

for year in range(2014,2021):
  file_year = xr.open_dataset(path_netcdf_in + str(year) + "_imerg_early_p.nc")
  file_year = file_year.sel(time = file_year.time.dt.year == year)
  file_year_plus1 = xr.open_dataset(path_netcdf_in + str(year+1) + "_imerg_early_p.nc")
  file_year_plus1 = file_year_plus1.sel(time = file_year_plus1.time.dt.year == year)
  encoding = {v: {'zlib': True, 'complevel': 5} for v in ["p"]}
  file_merged = xr.concat([file_year, file_year_plus1], dim="time")
  # monthly files
  for day_i in np.unique(file_merged["time"].dt.strftime('%m').values):
    file_merged_i = file_merged.sel(time=file_merged["time"].dt.strftime('%m') == day_i)
    np.round(file_merged_i, 1).to_netcdf(path_netcdf_out + str(year) + "-" + day_i + "_imerg_early.nc",
                                         encoding=encoding, engine='netcdf4')

import os
[os.remove(i) for i in sorted(glob.glob("./data/processed/gridded/IMERG-Early/*_p.nc"))]
[os.remove(i) for i in sorted(glob.glob("./data/processed/gridded/IMERG-Early/2014-*.nc"))]  

reticulate::use_virtualenv("/home/waldo/PycharmProjects/forR/venv/", required = TRUE)
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
  i_year_str = i_year.split("/")[5].split(".")[0]
  i_time_range = pd.date_range(start = i_year_str + "-01-01 00:00:00", periods = len(i_year_nc.z), freq = "H")
  
  new_i_year_nc = []
  for i_time in range(len(i_year_nc.z)):
    to_compute = i_year_nc.isel(z=i_time)
    to_save = to_compute.assign_coords(time=i_time_range[i_time])
    to_save = to_save.reindex_like(PISCOp_grid, method="nearest").variable
    to_save = to_save.where((to_save >= 0) | to_save.isnull())
    to_save = to_save.rio.write_nodata(np.nan)
    to_save = to_save.rio.write_crs("EPSG:3857")
    to_save = to_save.rio.interpolate_na(method="nearest")
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
  np.round(file_merged, 1).to_netcdf(path_netcdf_out + str(year) + "_imerg_early.nc", encoding=encoding, engine='netcdf4')


import os
[os.remove(i) for i in sorted(glob.glob("./data/processed/gridded/IMERG-Early/*_p.nc"))]
  
#file_merged_daily = file_merged.resample(time="1D").sum()
  #file_merged_daily2hourly = file_merged_daily.resample(time="1H").ffill()
  #file_merged_daily2hourly = xr.Dataset(data_vars=dict(p=(["time", "latitude", "longitude"], np.repeat(file_merged_daily.p, 24, axis=0))),
  #                                       coords=dict(time=file_merged.time, latitude=file_merged.latitude, longitude=file_merged.longitude))
  #file_merged_daily2hourly = (np.round(100 * (file_merged + 0.000001)/(file_merged_daily2hourly + 0.000001), 2))
  #print(file_merged_daily2hourly.sizes)
  #file_merged_daily2hourly.to_netcdf(path_netcdf_out + str(year) + "_gpm_imerg_early_pr.nc", encoding=encoding, engine='netcdf4')
  
  
  
  

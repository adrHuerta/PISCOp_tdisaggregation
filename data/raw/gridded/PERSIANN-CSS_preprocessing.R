reticulate::use_virtualenv("/home/waldo/PycharmProjects/forR/venv/", required=TRUE)
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

files_early = sorted(glob.glob("./data/raw/gridded/PERSIANN-CSS/*.nc"))

for i_year in files_early:
  i_year_nc = xr.open_dataset(i_year)
  i_year_nc = i_year_nc.astype("float32")
  i_year_str = i_year.split("_")[-1].split(".")[0]
  
  i_time_range = pd.date_range(start=i_year_str + "-01-01 00:00:00", periods=len(i_year_nc.time), freq="H")
  print(i_year)
  new_i_year_nc = []
  
  for i_time in range(len(i_year_nc.time)):
    print(i_time)
    to_compute = i_year_nc.isel(time=i_time)
    to_save = to_compute.assign_coords(time=i_time_range[i_time])
    to_save = to_save.reindex_like(PISCOp_grid, method="nearest").p
    #to_save = to_save.where((to_save >= 0) | to_save.isnull())
    #to_save = to_save.astype("float32")
    to_save = to_save.rio.write_nodata(np.nan)
    to_save = to_save.rio.write_crs("EPSG:3857")
    to_save = to_save.rio.interpolate_na(method="nearest")
    to_save = to_save.where(PISCOp_grid == True)
    to_save = (to_save + 0).to_dataset(name="p").drop(["crs", "z"])
    to_save = np.round(to_save, 1)
    new_i_year_nc.append(to_save)
    
  encoding = {v: {'zlib': True, 'complevel': 5} for v in ["p"]}
  gpmimerg_early = xr.concat(new_i_year_nc, dim="time")
  gpmimerg_early["time"] = pd.to_datetime(gpmimerg_early.time.values) - pd.Timedelta(hours=5)  # UTC to local time
  gpmimerg_early["time"] = pd.to_datetime(gpmimerg_early.time.values).shift(periods=-8, freq="H")  # 7pm-7am daily sum
  gpmimerg_early.to_netcdf("/home/waldo/Documentos/Repos/PISCOp_tdisaggregation/data/processed/gridded/PERSIANN-CSS/" + i_year_str + "_persiann_css_p.nc", encoding=encoding,
                           engine='netcdf4')

#·····································#
  
path_netcdf_in = "./data/processed/gridded/PERSIANN-CSS/"
path_netcdf_out = "./data/processed/gridded/PERSIANN-CSS/"

for year in range(2014,2021):
  file_year = xr.open_dataset(path_netcdf_in + str(year) + "_persiann_css_p.nc")
  file_year = file_year.sel(time = file_year.time.dt.year == year)
  file_year_plus1 = xr.open_dataset(path_netcdf_in + str(year+1) + "_persiann_css_p.nc")
  file_year_plus1 = file_year_plus1.sel(time = file_year_plus1.time.dt.year == year)
  encoding = {v: {'zlib': True, 'complevel': 5} for v in ["p"]}
  file_merged = xr.concat([file_year, file_year_plus1], dim="time")
  np.round(file_merged, 1).to_netcdf(path_netcdf_out + str(year) + "_persian_css.nc", encoding=encoding, engine='netcdf4')


  
import os
[os.remove(i) for i in sorted(glob.glob("./data/processed/gridded/PERSIANN-CSS/*_p.nc"))]
  
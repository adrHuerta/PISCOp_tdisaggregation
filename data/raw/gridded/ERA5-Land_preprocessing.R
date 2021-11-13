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

files_era5land = sorted(glob.glob("./data/raw/gridded/ERA5-Land/*.nc"))[1:]

for i_year in files_era5land:
  
  i_year_nc = xr.open_dataset(i_year)
  i_year_str = i_year.split("/")[5].split(".")[0]
  
  new_i_year_nc = []
  for i_time in pd.to_datetime(i_year_nc.time.values):
    
    to_compute = i_year_nc.sel(time=i_time)
    if i_time.strftime('%Y-%m-%d %H') == (i_year_str + "-01-01 00"):
      to_compute_previous = xr.open_dataset(i_year.replace(i_year_str, str(int( i_year_str )-1)))
      to_compute_previous = to_compute_previous.sel(time = i_time - pd.Timedelta(hours=1))
      to_save = (to_compute - to_compute_previous)*1000
      to_save = to_save.assign_coords(time=i_time)
      to_save = to_save.reindex_like(PISCOp_grid, method="nearest").tp
      to_save = to_save.where((to_save >= 0) | to_save.isnull())
      to_save = to_save.rio.write_crs(shp_Peru.crs)
      to_save = to_save.rio.write_nodata(np.nan)
      to_save = to_save.rio.interpolate_na(method = "nearest")
      to_save = to_save.astype("float32")
      to_save = np.round(to_save, 1)
      to_save = to_save.where(PISCOp_grid == True).drop(["z", "spatial_ref"]).to_dataset(name = "p")
      
    elif i_time.strftime('%H') == "01":
      
      to_save = to_compute*1000
      to_save = to_save.assign_coords(time=i_time)
      to_save = to_save.reindex_like(PISCOp_grid, method="nearest").tp
      to_save = to_save.where((to_save >= 0) | to_save.isnull())
      to_save = to_save.rio.write_crs(shp_Peru.crs)
      to_save = to_save.rio.write_nodata(np.nan)
      to_save = to_save.rio.interpolate_na(method = "nearest")
      to_save = to_save.astype("float32")
      to_save = np.round(to_save, 1)
      to_save = to_save.where(PISCOp_grid == True).drop(["z", "spatial_ref"]).to_dataset(name = "p")
      
    else:
      to_compute_previous = i_year_nc.sel(time = i_time - pd.Timedelta(hours=1))
      to_save = (to_compute - to_compute_previous)*1000
      to_save = to_save.assign_coords(time=i_time)
      to_save = to_save.reindex_like(PISCOp_grid, method="nearest").tp
      to_save = to_save.where((to_save >= 0) | to_save.isnull())
      to_save = to_save.rio.write_crs(shp_Peru.crs)
      to_save = to_save.rio.write_nodata(np.nan)
      to_save = to_save.rio.interpolate_na(method = "nearest")
      to_save = to_save.astype("float32")
      to_save = np.round(to_save, 1)
      to_save = to_save.where(PISCOp_grid == True).drop(["z", "spatial_ref"]).to_dataset(name = "p")
    
    #print(i_time)
    new_i_year_nc.append(to_save)
  
  encoding = {v: {'zlib': True, 'complevel': 5} for v in ["p"]}
  era5land_p = xr.concat(new_i_year_nc, dim="time")
  era5land_p["time"] = pd.to_datetime(era5land_p.time.values) - pd.Timedelta(hours=5)
  era5land_p["time"] = pd.to_datetime(era5land_p.time.values).shift(periods=-8, freq="H")  # 7pm-7am daily sum
  era5land_p.to_netcdf("./data/processed/gridded/ERA5-Land/" + i_year_str + "_era5land_p.nc", encoding=encoding, engine='netcdf4')

#···················································#

path_netcdf_in = "./data/processed/gridded/ERA5-Land/"
path_netcdf_out = "./data/processed/gridded/ERA5-Land/"

for year in range(2014,2021):
  file_year = xr.open_dataset(path_netcdf_in + str(year) + "_era5land_p.nc")
  file_year = file_year.sel(time = file_year.time.dt.year == year)
  file_year_plus1 = xr.open_dataset(path_netcdf_in + str(year+1) + "_era5land_p.nc")
  file_year_plus1 = file_year_plus1.sel(time = file_year_plus1.time.dt.year == year)
  
  encoding = {v: {'zlib': True, 'complevel': 5} for v in ["p"]}
  file_merged = xr.concat([file_year, file_year_plus1], dim="time")
  np.round(file_merged, 1).to_netcdf(path_netcdf_out + str(year) + "_era5land.nc", encoding=encoding, engine='netcdf4')

  
import os
[os.remove(i) for i in sorted(glob.glob("./data/processed/gridded/ERA5-Land/*_p.nc"))]
  
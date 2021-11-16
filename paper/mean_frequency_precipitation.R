reticulate::use_virtualenv("/home/adrian/Documents/Repos/wa_eps_budyko/venv/", required = TRUE)
reticulate::repl_python()

import numpy as np
import glob
import xarray as xr
from cdo import Cdo
cdo = Cdo()

def freq_of_wet_days_01(x):
  res = x[x >= 0.1]
  res = len(x)*100/len(res)
  return res

def freq_of_wet_days_5(x):
  res = x[x >= 5]
  res = len(x)*100/len(res)
  return res
  
seasons = [["12", "01", "02"],["06", "07", "08"]]
for season in range(len(seasons)):
  print(season)
  files_grid_0 = sorted(glob.glob("data/processed/gridded/PISCOp_hourly/*-" + seasons[season][0] + "-*.nc"))
  files_grid_1 = sorted(glob.glob("data/processed/gridded/PISCOp_hourly/*-" + seasons[season][1] + "-*.nc"))
  files_grid_2 = sorted(glob.glob("data/processed/gridded/PISCOp_hourly/*-" + seasons[season][2] + "-*.nc"))
  files_grid = [*files_grid_0, *files_grid_1, *files_grid_2]
  merged_files_grid = cdo.cat(input=' '.join(files_grid))
  
  merged_files_grid = xr.open_dataset(merged_files_grid, chunks={"latitude": 100, "longitude": 100})
  freq_grid_01 = xr.apply_ufunc(freq_of_wet_days_01, merged_files_grid, input_core_dims=[['time']], output_dtypes="float32", vectorize=True, dask = "parallelized")
  freq_grid_01.to_netcdf("paper/output/PISCOp_hourly_frequency_01_" + "_".join(seasons[season]) + ".nc")
  freq_grid_5 = xr.apply_ufunc(freq_of_wet_days_5, merged_files_grid, input_core_dims=[['time']], output_dtypes="float32", vectorize=True, dask = "parallelized")
  freq_grid_5.to_netcdf("paper/output/PISCOp_hourly_frequency_5_" + "_".join(seasons[season]) + ".nc")
  
  cdo.cleanTempDir()


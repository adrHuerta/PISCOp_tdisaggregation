reticulate::use_virtualenv("/home/adrian/Documents/Repos/wa_eps_budyko/venv/", required = TRUE)
reticulate::repl_python()

import numpy as np
import glob
import xarray as xr
from cdo import Cdo
cdo = Cdo()

def mean_no_zero(x):
  res = np.mean(x[x >= 0.1])
  return res


seasons = [["12", "01", "02"], ["03", "04", "05"], ["06", "07", "08"], ["09", "10", "11"]]

for season in range(len(seasons)):
  print(season)
  files_grid_0 = sorted(glob.glob("data/processed/gridded/PISCOp_hourly/*-" + seasons[season][0] + "-*.nc"))
  files_grid_1 = sorted(glob.glob("data/processed/gridded/PISCOp_hourly/*-" + seasons[season][1] + "-*.nc"))
  files_grid_2 = sorted(glob.glob("data/processed/gridded/PISCOp_hourly/*-" + seasons[season][2] + "-*.nc"))
  files_grid = [*files_grid_0, *files_grid_1, *files_grid_2]
  merged_files_grid = cdo.cat(input=' '.join(files_grid))
  
  merged_files_grid = xr.open_dataset(merged_files_grid, chunks={"latitude": 100, "longitude": 100})
  intensity_grid = xr.apply_ufunc(mean_no_zero, merged_files_grid, input_core_dims=[['time']], output_dtypes=['float32'], vectorize=True, dask = "parallelized")
  intensity_grid.to_netcdf("paper/output/PISCOp_hourly_intensity_" + "_".join(seasons[season]) + ".nc")
  
  cdo.cleanTempDir()
  


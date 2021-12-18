reticulate::use_virtualenv("/home/waldo/PycharmProjects/forR/venv/", required = TRUE)
reticulate::repl_python()

import os
os.chdir("/home/waldo/Documentos/Repos/PISCOp_tdisaggregation")

import numpy as np
import glob
import xarray as xr
from cdo import Cdo

cdo = Cdo()


def hourly_cycle(x):
  res = np.mean(np.reshape(x, (-1, 24)), axis=0)
return res


def get_time_of_max_value(x):
  if all(np.isnan(x)):
  res = np.nan
else:
  res = np.argmax(x)
return res


def amplitude_cycle(x):
  res = np.max(x) - np.min(x)
return res

seasons = [["12", "01", "02"]]
season = 0

#
files_grid_0 = sorted(glob.glob("data/processed/gridded/PISCOp_h/*-" + seasons[season][0] + "-*.nc"))
files_grid_1 = sorted(glob.glob("data/processed/gridded/PISCOp_h/*-" + seasons[season][1] + "-*.nc"))
files_grid_2 = sorted(glob.glob("data/processed/gridded/PISCOp_h/*-" + seasons[season][2] + "-*.nc"))
# files_grid_3 = sorted(glob.glob("data/processed/gridded/PISCOp_h/*-" + seasons[season][3] + "-*.nc"))
# files_grid_4 = sorted(glob.glob("data/processed/gridded/PISCOp_h/*-" + seasons[season][4] + "-*.nc"))
# files_grid_5 = sorted(glob.glob("data/processed/gridded/PISCOp_h/*-" + seasons[season][5] + "-*.nc"))
# files_grid = [*files_grid_0, *files_grid_1, *files_grid_2, *files_grid_3, *files_grid_4, *files_grid_5]
files_grid = [*files_grid_0, *files_grid_1, *files_grid_2]

merged_files_grid = cdo.cat(input=' '.join(files_grid))
merged_files_grid = xr.open_dataset(merged_files_grid, chunks={"latitude": 100, "longitude": 100})
cycle_grid = xr.apply_ufunc(hourly_cycle, merged_files_grid, input_core_dims=[['time']], output_core_dims=[['time2']],
                            output_sizes={"time2": 24}, output_dtypes="float32", vectorize=True, dask="parallelized")
cycle_grid.to_netcdf("paper/output/PISCOp_h_hourly_cycle_" + "_".join(seasons[season]) + ".nc")
cycle_grid = xr.open_dataset("paper/output/PISCOp_h_hourly_cycle_" + "_".join(seasons[season]) + ".nc")
xr.apply_ufunc(get_time_of_max_value, cycle_grid, input_core_dims=[['time2']], vectorize=True).to_netcdf(
  "paper/output/PISCOp_h_hourly_cycle_maxvalue_" + "_".join(seasons[season]) + ".nc")
xr.apply_ufunc(amplitude_cycle, cycle_grid, input_core_dims=[['time2']], vectorize=True).to_netcdf(
  "paper/output/PISCOp_h_hourly_cycle_amplitude_" + "_".join(seasons[season]) + ".nc")

cdo.cleanTempDir()

#
files_grid_0 = sorted(glob.glob("data/processed/gridded/PISCOp_h_non-DBC/*-" + seasons[season][0] + "-*.nc"))
files_grid_1 = sorted(glob.glob("data/processed/gridded/PISCOp_h_non-DBC/*-" + seasons[season][1] + "-*.nc"))
files_grid_2 = sorted(glob.glob("data/processed/gridded/PISCOp_h_non-DBC/*-" + seasons[season][2] + "-*.nc"))
# files_grid_3 = sorted(glob.glob("data/processed/gridded/PISCOp_hourly_mean_SAT/*-" + seasons[season][3] + "-*.nc"))
# files_grid_4 = sorted(glob.glob("data/processed/gridded/PISCOp_hourly_mean_SAT/*-" + seasons[season][4] + "-*.nc"))
# files_grid_5 = sorted(glob.glob("data/processed/gridded/PISCOp_hourly_mean_SAT/*-" + seasons[season][5] + "-*.nc"))
# files_grid = [*files_grid_0, *files_grid_1, *files_grid_2, *files_grid_3, *files_grid_4, *files_grid_5]
files_grid = [*files_grid_0, *files_grid_1, *files_grid_2]

merged_files_grid = cdo.cat(input=' '.join(files_grid))
merged_files_grid = xr.open_dataset(merged_files_grid, chunks={"latitude": 100, "longitude": 100})
cycle_grid = xr.apply_ufunc(hourly_cycle, merged_files_grid, input_core_dims=[['time']], output_core_dims=[['time2']],
                            output_sizes={"time2": 24}, output_dtypes="float32", vectorize=True, dask="parallelized")
cycle_grid.to_netcdf("paper/output/PISCOp_h_non-DBC_hourly_cycle_" + "_".join(seasons[season]) + ".nc")
cycle_grid = xr.open_dataset("paper/output/PISCOp_h_non-DBC_hourly_cycle_" + "_".join(seasons[season]) + ".nc")
xr.apply_ufunc(get_time_of_max_value, cycle_grid, input_core_dims=[['time2']], vectorize=True).to_netcdf(
  "paper/output/PISCOp_h_non-DBC_hourly_cycle_maxvalue_" + "_".join(seasons[season]) + ".nc")
xr.apply_ufunc(amplitude_cycle, cycle_grid, input_core_dims=[['time2']], vectorize=True).to_netcdf(
  "paper/output/PISCOp_h_non-DBC_hourly_cycle_amplitude_" + "_".join(seasons[season]) + ".nc")

cdo.cleanTempDir()

#
files_grid_0 = sorted(glob.glob("data/processed/gridded/AWSs_by_day/*-" + seasons[season][0] + "-*.nc"))
files_grid_1 = sorted(glob.glob("data/processed/gridded/AWSs_by_day/*-" + seasons[season][1] + "-*.nc"))
files_grid_2 = sorted(glob.glob("data/processed/gridded/AWSs_by_day/*-" + seasons[season][2] + "-*.nc"))
# files_grid_3 = sorted(glob.glob("data/processed/gridded/AWSs_by_day/*-" + seasons[season][3] + "-*.nc"))
# files_grid_4 = sorted(glob.glob("data/processed/gridded/AWSs_by_day/*-" + seasons[season][4] + "-*.nc"))
# files_grid_5 = sorted(glob.glob("data/processed/gridded/AWSs_by_day/*-" + seasons[season][5] + "-*.nc"))
# files_grid = [*files_grid_0, *files_grid_1, *files_grid_2, *files_grid_3, *files_grid_4, *files_grid_5]
files_grid = [*files_grid_0, *files_grid_1, *files_grid_2]

merged_files_grid = cdo.cat(input=' '.join(files_grid))
merged_files_grid = xr.open_dataset(merged_files_grid, chunks={"latitude": 100, "longitude": 100})
cycle_grid = xr.apply_ufunc(hourly_cycle, merged_files_grid, input_core_dims=[['time']], output_core_dims=[['time2']],
                            output_sizes={"time2": 24}, output_dtypes="float32", vectorize=True, dask="parallelized")
cycle_grid.to_netcdf("paper/output/AWSs_hourly_hourly_cycle_" + "_".join(seasons[season]) + ".nc")
cycle_grid = xr.open_dataset("paper/output/AWSs_hourly_hourly_cycle_" + "_".join(seasons[season]) + ".nc")
xr.apply_ufunc(get_time_of_max_value, cycle_grid, input_core_dims=[['time2']], vectorize=True).to_netcdf(
  "paper/output/AWSs_hourly_hourly_cycle_maxvalue_" + "_".join(seasons[season]) + ".nc")
xr.apply_ufunc(amplitude_cycle, cycle_grid, input_core_dims=[['time2']], vectorize=True).to_netcdf(
  "paper/output/AWSs_hourly_hourly_cycle_amplitude_" + "_".join(seasons[season]) + ".nc")

cdo.cleanTempDir()

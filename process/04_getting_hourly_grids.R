reticulate::use_virtualenv("/home/adrian/Documents/Repos/wa_eps_budyko_cc/venv/", required = TRUE)
reticulate::repl_python()

import numpy as np
import pandas as pd
import xarray as xr
import glob
from joblib import Parallel, delayed

exec(open("src/wet0dray.py").read())

PISCOpd = sorted(glob.glob("data/processed/gridded/PISCOpd/*.nc"))[1:]
PISCOpd = xr.concat([xr.open_dataset(grid) for grid in PISCOpd], dim="time")
time_range = (pd.date_range(start = "2015-01-01", periods = len(PISCOpd.time), freq = "D")).strftime("%Y.%m.%d")
# step_time = PISCOpd.time.dt.strftime('%Y-%m-%d').values[0]
encoding = {v: {'zlib': True, 'complevel': 5} for v in ["p"]}

def getting_hourly_files(step_time):
  # from SATc
  # hourly files
  hourly_files = sorted(glob.glob("data/processed/gridded/SATc/SATc_" + step_time + "*.nc"))
  hourly_files_dates = pd.to_datetime([text.split("/")[-1].split("_")[-1].split(".nc")[0] for text in hourly_files], format="%Y.%m.%d.%H.%M.%S")
  hourly_files = [xr.open_dataset(grid) for grid in hourly_files]
  # hourly 2 daily
  daily_file = xr.concat(hourly_files, dim="time").sum(dim="time").p
  # daily PISCOp file
  PISCOpd_daily_file = PISCOpd.sel(time = step_time.replace(".","-")).pcp
  # applying ratio based on values of daily PISCOp y corrected SAT
  PISCOpd_hourly_files = [PISCOpd_daily_file * (xr.apply_ufunc(wetOdray, daily_file, PISCOpd_daily_file, grid, vectorize=True)) for grid in hourly_files]
  PISCOpd_hourly_files = np.round(xr.concat(PISCOpd_hourly_files, dim="time").drop("crs"), 1)
  PISCOpd_hourly_files["time"] = hourly_files_dates
  PISCOpd_hourly_files.to_netcdf("data/processed/gridded/PISCOp_h/PISCOp_h_" + step_time.replace(".","-") + ".nc", encoding=encoding, engine='netcdf4')
  
  # from SAT
  hourly_files_1 = sorted(glob.glob("data/processed/gridded/SAT/SAT_" + step_time.replace(".","-") + "*.nc"))
  hourly_files_dates_1 = pd.to_datetime([text.split("/")[-1].split("_")[-1].split(".nc")[0] for text in hourly_files_1], format="%Y-%m-%d %H:%M:%S")
  hourly_files_1 = [xr.open_dataset(grid) for grid in hourly_files_1]
  # hourly 2 daily
  daily_file_1 = xr.concat(hourly_files_1, dim="time").sum(dim="time").p
  # daily PISCOp file
  PISCOpd_daily_file_1 = PISCOpd.sel(time = step_time.replace(".","-")).pcp
  # applying ratio based on values of daily PISCOp y corrected SAT
  PISCOpd_hourly_files_1 = [PISCOpd_daily_file_1 * (xr.apply_ufunc(wetOdray, daily_file_1, PISCOpd_daily_file, grid, vectorize=True)) for grid in hourly_files_1]
  PISCOpd_hourly_files_1 = np.round(xr.concat(PISCOpd_hourly_files_1, dim="time").drop("crs"), 1)
  PISCOpd_hourly_files_1["time"] = hourly_files_dates_1
  PISCOpd_hourly_files_1.to_netcdf("data/processed/gridded/PISCOp_h_non-DBC/PISCOp_h_noDBC_" + step_time.replace(".","-") + ".nc", encoding=encoding, engine='netcdf4')  


Parallel(n_jobs=1, verbose=50)(
  delayed(getting_hourly_files)(i) for i in time_range
)

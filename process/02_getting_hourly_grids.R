reticulate::use_virtualenv("/home/waldo/PycharmProjects/forR/venv/", required = TRUE)
reticulate::repl_python()

import numpy as np
import pandas as pd
import xarray as xr
import glob
from joblib import Parallel, delayed

exec(open("src/wet0dray.py").read())

PISCOpd = sorted(glob.glob("data/processed/gridded/PISCOpd/*.nc"))[1:]
PISCOpd = xr.concat([xr.open_dataset(grid) for grid in PISCOpd], dim="time")
step_time = PISCOpd.time.dt.strftime('%Y-%m-%d').values[0]
encoding = {v: {'zlib': True, 'complevel': 5} for v in ["p"]}

def getting_hourly_files(step_time):
  # hourly files
  hourly_files = sorted(glob.glob("data/processed/gridded/SATc/" + step_time + "*.nc"))
  hourly_files_dates = pd.to_datetime([text.split("/")[-1].split("_")[0] for text in hourly_files], format="%Y-%m-%d %H:%M:%S")
  hourly_files = [xr.open_dataset(grid) for grid in hourly_files]
  # hourly 2 daily
  daily_file = xr.concat(hourly_files, dim="time").sum(dim="time").layer
  # daily PISCOp file
  PISCOpd_daily_file = PISCOpd.sel(time=PISCOpd.time.dt.strftime('%Y-%m-%d') == step_time).pcp
  # applying ratio based on values of daily PISCOp y corrected SAT
  PISCOpd_hourly_files = [PISCOpd_daily_file * (xr.apply_ufunc(wetOdray, daily_file, PISCOpd_daily_file, grid, vectorize=True)) for grid in hourly_files]
  PISCOpd_hourly_files = np.round(xr.concat(PISCOpd_hourly_files, dim="time").drop("crs").rename({"layer": "p"}), 1)
  PISCOpd_hourly_files["time"] = hourly_files_dates
  PISCOpd_hourly_files.to_netcdf("data/processed/gridded/PISCOp_hourly/PISCOp_hourly_" + step_time + ".nc", encoding=encoding, engine='netcdf4')


Parallel(n_jobs=2, verbose=50)(
  delayed(getting_hourly_files)(i) for i in PISCOpd.time.dt.strftime('%Y-%m-%d').values
)
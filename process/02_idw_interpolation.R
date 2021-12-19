rm(list = ls())
"%>%" = magrittr::`%>%`

# source('./src/oidw.R')

# observed data
aws_data <- readRDS("./data/processed/obs/AWS/AWSs.RDS")

# PISCOp grid
PISCOp_grid <- raster::raster("./data/others/PISCOp_grid_mask.nc")

output_file = "data/processed/gridded/AWSs"

# interpolation
# parallel::mclapply(1:nrow(aws_data$values), function(time_step){
#     
#     xyz_i <- aws_data$xyz
#     xyz_i@data$value <- as.numeric(aws_data$values[time_step, ])
#     xyz_i <- xyz_i[complete.cases(xyz_i@data), ]
# 
#     
#     idw <- O_IDW(formula_i = value ~ 1, location_i = xyz_i, grid_i = PISCOp_grid)
#     name_to_save <- format(time(aws_data$values[time_step, ]), "%Y-%m-%d %H:%M:%S")
#     
#     raster::writeRaster(x = idw,
#                         varname = "p",
#                         filename = file.path(output_file,
#                                              sprintf("%s_%s.nc", "AWSs",  name_to_save)),
#                         datatype = 'FLT4S', force_v4 = TRUE, compression = 7)
#   
#   }, mc.cores = 12)

####
####
# for technical validation

parallel::mclapply(1:nrow(aws_data$values), function(time_step){
  
  xyz_i <- aws_data$xyz
  xyz_i@data$value <- as.numeric(aws_data$values[time_step, ])
  xyz_i <- xyz_i[complete.cases(xyz_i@data), ]
  
  gs <- gstat::gstat(formula = value ~ 1, locations = xyz_i, set = list(idp = 2))
  idw <- raster::interpolate(PISCOp_grid, gs)
  
  name_to_save <- format(time(aws_data$values[time_step, ]), "%Y-%m-%d %H:%M:%S")
  
  raster::writeRaster(x = idw,
                      varname = "p",
                      filename = file.path("data/processed/gridded/AWSs",
                                           sprintf("%s_%s.nc", "AWSs",  name_to_save)),
                      datatype = 'FLT4S', force_v4 = TRUE, compression = 7)
  
}, mc.cores = 12)


reticulate::use_virtualenv("/home/waldo/PycharmProjects/forR/venv/", required = TRUE)
reticulate::repl_python()

import numpy as np
import pandas as pd
import xarray as xr
import glob
from joblib import Parallel, delayed

PISCOpd = sorted(glob.glob("data/processed/gridded/PISCOpd/*.nc"))[1:]
PISCOpd = xr.concat([xr.open_dataset(grid) for grid in PISCOpd], dim="time")
time_range = (pd.date_range(start = "2015-01-01", periods = len(PISCOpd.time), freq = "D")).strftime("%Y-%m-%d")
encoding = {v: {'zlib': True, 'complevel': 5} for v in ["p"]}

def getting_hourly_files(step_time):
  # from mean_SATc
  # hourly files
  hourly_files = sorted(glob.glob("data/processed/gridded/AWSs/AWSs_" + step_time + "*.nc"))
  hourly_files_dates = pd.to_datetime([text.split("/")[-1].split("_")[-1].split(".nc")[0] for text in hourly_files], format="%Y-%m-%d %H:%M:%S")
  hourly_files = [xr.open_dataset(grid) for grid in hourly_files]
  # hourly 2 daily
  hourly_files = np.round(xr.concat(hourly_files, dim="time").drop("crs"), 1)
  hourly_files["time"] = hourly_files_dates
  hourly_files.to_netcdf("data/processed/gridded/AWSs_by_day/AWSs_" + step_time + ".nc", encoding=encoding, engine='netcdf4')
  

Parallel(n_jobs=1, verbose=50)(
  delayed(getting_hourly_files)(i) for i in time_range
  )
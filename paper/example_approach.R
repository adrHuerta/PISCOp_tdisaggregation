library(xts)
library(raster)
library(gstat)
rm(list = ls())
"%>%" = magrittr::`%>%`

source('./src/make_covariables_and_k_values.R')
source('./src/autofitVariogramPISCOp.R')

output_path = "./data/processed/gridded/SATc/"

# obs data
aws_data <- read.csv("data/processed/obs/AWS/AWS_data.csv", stringsAsFactors = FALSE)
aws_data <- xts::xts(aws_data[,-1], as.POSIXct(aws_data[,1]))
aws_data <- aws_data["2015/"]
aws_xyz <- read.csv("data/processed/obs/AWS/AWS_xyz.csv", stringsAsFactors = FALSE)

# gridded data 
imerg_early <- lapply(dir("data/processed/gridded/IMERG-Early", full.names = TRUE)[-c(1)],
                      function(x){
                        raster::brick(x)
                      })
names(imerg_early) <- c(2015:2020)

# spatial xyz data
sp_xyz <- sp::SpatialPointsDataFrame(coords = aws_xyz[, c("LON", "LAT")],
                                     data = aws_xyz[, c("CODE", "ESTACION")],
                                     proj4string = sp::CRS(raster::projection(imerg_early[[1]])))

step_time = "2015-01-04 13:00:00"

step_time_data <- make_covariables(date_time = step_time,
                                   covs_list = c(imerg_early = raster::subset(imerg_early[[substr(step_time, 1, 4)]], 
                                                                              which(raster::getZ(imerg_early[[substr(step_time, 1, 4)]]) == step_time))),
                                   obs_xyz = sp_xyz,
                                   obs = aws_data[step_time])

grid2point <- raster::extract(step_time_data$covs, step_time_data$obs, cellnumber = FALSE, sp = TRUE)
grid2point$ratio <- (sqrt(grid2point@data$value) + 1)/(sqrt(grid2point@data$imerg_early) + 1)
grid2point <- grid2point[complete.cases(grid2point@data), ]
grid2point$ratio[grid2point$ratio > 2.5] <- 2.5

if(sum(grid2point@data$ratio == 1) > length(grid2point@data$ratio)*70/100) {
  
  grid_res <- (sqrt(step_time_data$covs))^2
  
} else {
  
  variogram_fit <- autofitVariogramPISCOp(ratio ~ 1, input_data = grid2point, fix.values = c(0,NA,NA))
  gridded_location <- as(step_time_data$covs, 'SpatialGrid')
  gs <- gstat::gstat(formula = ratio ~ 1, 
                     locations = grid2point, 
                     model = variogram_fit$var_model)
  grid_res <- raster::predict(gs, gridded_location)
  grid_res_d <- raster::brick(grid_res)[["var1.pred"]]
  grid_res <- (sqrt(step_time_data$covs)*grid_res_d)^2
}

grid_res <- raster::brick(grid_res, step_time_data$covs)
names(grid_res) <- c("IMERG-Early-c", "IMERG-Early")
spplot(grid_res)
spplot(grid_res_d)

###

reticulate::use_virtualenv("/home/adrian/PycharmProjects/hourly_PISCOp/venv/", required = TRUE)
reticulate::repl_python()

import glob
import os
import xarray as xr
import pandas as pd
import rioxarray
from geopandas import read_file as gpd_read_file
from numpy import isnan as np_isnan
import numpy as np
import matplotlib.pyplot as plt

#os.chdir("/home/adrian/Documents/Repos/PISCOp_tdisaggregation")
exec(open("src/wet0dray.py").read())
exec(open("src/crop_mask_shp_in_netcdf.py").read())

shp_chirilu = gpd_read_file('data/others/CHIRILU.shp')
date_example = "2015-01-04"

PISCOpd = sorted(glob.glob("data/processed/gridded/PISCOpd/*.nc"))[1:]
PISCOpd = xr.concat([xr.open_dataset(grid) for grid in PISCOpd], dim="time")
hourly_files = sorted(glob.glob("data/processed/gridded/SATc/" + date_example + "*.nc"))
hourly_files_dates = pd.to_datetime([text.split("/")[-1].split("_")[0] for text in hourly_files], format="%Y-%m-%d %H:%M:%S")
hourly_files = [xr.open_dataset(grid) for grid in hourly_files]
daily_file = xr.concat(hourly_files, dim="time").sum(dim="time").layer
PISCOpd_daily_file = PISCOpd.sel(time=PISCOpd.time.dt.strftime('%Y-%m-%d') == date_example).pcp

fig, ax = plt.subplots(figsize=(7,7))
xr.apply_ufunc(wetOdray, daily_file, PISCOpd_daily_file, hourly_files[1], vectorize=True).rename({"layer":"ratio"}).ratio.plot(ax=ax)
ax.set_ylabel("")
ax.set_xlabel("")
ax.set_title("")
plt.savefig('paper/ratio_imerg_early_c_hourly_vs_daily.png')

PISCOpd_hourly_files = [PISCOpd_daily_file * (xr.apply_ufunc(wetOdray, daily_file, PISCOpd_daily_file, grid, vectorize=True)) for grid in hourly_files]
PISCOpd_hourly_files_to_daily = xr.concat(PISCOpd_hourly_files, dim="time").sum(dim="time")
fig, ax = plt.subplots(figsize=(7,7))
(PISCOpd_hourly_files_to_daily.layer - PISCOpd_daily_file).plot(ax=ax)
ax.set_ylabel("")
ax.set_xlabel("")
ax.set_title("")
plt.savefig('paper/difference_daily_original_vs_daily_from_hourly.png')

###########

imerg_early = xr.open_dataset("data/processed/gridded/IMERG-Early/" + date_example[0:4] + "_imerg_early.nc")
imerg_early = imerg_early.sel(time = date_example).p
imerg_early = xr_crop(shp_i = shp_chirilu, netcdf_i = imerg_early)
shp_exp_grid = xr_shp_to_grid(shp_i = shp_chirilu, netcdf_array = imerg_early.isel(time=0))
imerg_early = xr_mask(grid_mask = shp_exp_grid, netcdf_i = imerg_early)

imerg_early_c = sorted(glob.glob("data/processed/gridded/SATc/" + date_example + "*.nc"))
imerg_early_c = xr.concat([xr.open_dataset(grid) for grid in imerg_early_c], dim="time").layer
imerg_early_c["time"] = imerg_early.time.values
imerg_early_c = xr_crop(shp_i = shp_chirilu, netcdf_i = imerg_early_c)
shp_exp_grid = xr_shp_to_grid(shp_i = shp_chirilu, netcdf_array = imerg_early_c.isel(time=0))
imerg_early_c = xr_mask(grid_mask = shp_exp_grid, netcdf_i = imerg_early_c)

piscop_hourly = xr.open_dataset("data/processed/gridded/PISCOp_hourly/PISCOp_hourly_" + date_example + ".nc").p
piscop_hourly = xr_crop(shp_i = shp_chirilu, netcdf_i = piscop_hourly)
shp_exp_grid = xr_shp_to_grid(shp_i = shp_chirilu, netcdf_array = piscop_hourly.isel(time=0))
piscop_hourly = xr_mask(grid_mask = shp_exp_grid, netcdf_i = piscop_hourly)

gridded_exp = xr.merge([imerg_early.to_dataset(name="IMERG-Early"), imerg_early_c.to_dataset(name="IMERG-Early-c"), piscop_hourly.to_dataset(name="PISCOp_hourly")])
gridded_exp_ts = gridded_exp.mean(dim=["latitude", "longitude"]).to_dataframe()


fig, ax = plt.subplots(figsize=(10,6))
gridded_exp_ts.drop(["crs","spatial_ref"], axis=1).plot(lw=3, style='.-',markersize=20, fontsize=10, ax=ax)
ax.set_xlabel("")
plt.savefig('paper/comparison_files.png')


##########


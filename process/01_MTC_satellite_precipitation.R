rm(list = ls())
"%>%" = magrittr::`%>%`

# creating time range
time_range <- seq(as.POSIXct("2015-01-01 00:00:00"), as.POSIXct("2020-12-31 23:00:00"), by = "hour")
dailyVar <- as.list(sort(unique(format(time_range, format = "%m-%d"))))
dailyVar[[59]] <- unlist(dailyVar[59:60])
dailyVar[[60]] <- NULL

#
output_file = "data/processed/gridded/SAT"

lapply(1:length(dailyVar), function(i){
  
  time_values <- dailyVar[[i]]
  
  imerg_early_files <- c(sapply(time_values, function(z){list.files("./data/processed/gridded/IMERG-Early", pattern = z, full.names = TRUE)}))
  imerg_early_files <- raster::brick(lapply(imerg_early_files, raster::brick))
  
  persiann_css_files <- c(sapply(time_values, function(z){list.files("./data/processed/gridded/IMERG-Early", pattern = z, full.names = TRUE)}))
  persiann_css_files <- raster::brick(lapply(persiann_css_files, raster::brick))
  
  gsmap_op_files <- c(sapply(time_values, function(z){list.files("./data/processed/gridded/GSMaP_op", pattern = z, full.names = TRUE)}))
  gsmap_op_files <- raster::brick(lapply(gsmap_op_files, raster::brick))
  
  # to log values
  # 1
  r_imerg <- raster::calc(imerg_early_files, fun = function(z){ log(z + .1)})
  # 2
  r_persiann <- raster::calc(persiann_css_files, fun = function(z){ log(z + .1)})
  # 3
  r_gsmap <- raster::calc(gsmap_op_files, fun = function(z){ log(z + .1)})
  
  # mean values 
  r_mean_imerg <- raster::calc(r_imerg, mean)
  r_mean_persiann <- raster::calc(r_persiann, mean)
  r_mean_gsmap <- raster::calc(r_gsmap, mean)
  
  # C 1,1
  C_imerg_imerg <- raster::calc((r_imerg - r_mean_imerg)*(r_imerg - r_mean_imerg), sum)/raster::nlayers(r_gsmap)
  # C 1,2
  C_imerg_persiann <- raster::calc((r_imerg - r_mean_imerg)*(r_persiann - r_mean_persiann), sum)/raster::nlayers(r_gsmap)
  # C 1,3
  C_imerg_gsmap <- raster::calc((r_imerg - r_mean_imerg)*(r_gsmap - r_mean_gsmap), sum)/raster::nlayers(r_gsmap)
  # C 2,3
  C_persiann_gsmap <- raster::calc((r_persiann - r_mean_persiann)*(r_gsmap - r_mean_gsmap), sum)/raster::nlayers(r_gsmap)
  # C 2,2
  C_persiann_persiann <- raster::calc((r_persiann - r_mean_persiann)*(r_persiann - r_mean_persiann), sum)/raster::nlayers(r_gsmap)
  # C 3,3
  C_gsmap_gsmap <- raster::calc((r_gsmap - r_mean_gsmap)*(r_gsmap - r_mean_gsmap), sum)/raster::nlayers(r_gsmap)

  # var1
  var_imerg <- C_imerg_imerg - ((C_imerg_persiann*C_imerg_gsmap) + .01)/(C_persiann_gsmap + .01)
  var_persiann <- C_persiann_persiann - ((C_imerg_persiann*C_persiann_gsmap) + .1)/(C_imerg_gsmap + .01)
  var_gsmap <- C_gsmap_gsmap - ((C_imerg_gsmap*C_persiann_gsmap) + .01)/(C_imerg_persiann + .01)
  # var1^2
  VAR_imerg_2 <- var_imerg*var_imerg
  VAR_persiann_2 <- var_persiann*var_persiann
  VAR_gsmap_2 <- var_gsmap*var_gsmap
  
  # weights
  w_imerg <- (VAR_persiann_2*VAR_gsmap_2)/(VAR_imerg_2*VAR_persiann_2 + VAR_persiann_2*VAR_gsmap_2 + VAR_imerg_2*VAR_gsmap_2)
  w_persiann <- (VAR_imerg_2*VAR_gsmap_2)/(VAR_imerg_2*VAR_persiann_2 + VAR_persiann_2*VAR_gsmap_2 + VAR_imerg_2*VAR_gsmap_2)
  w_gsmap <- (VAR_imerg_2*VAR_persiann_2)/(VAR_imerg_2*VAR_persiann_2 + VAR_persiann_2*VAR_gsmap_2 + VAR_imerg_2*VAR_gsmap_2)
  
  # TC merging
  tc_merging <- w_imerg*r_imerg + w_persiann*r_persiann + w_gsmap*r_gsmap
  tc_merging <- round(raster::calc(tc_merging, exp) -.1, 1)
  
  lapply(1:raster::nlayers(tc_merging), function(zi){
    raster::writeRaster(x = i_mean_sat_to_save[[zi]],
                        varname = "p",
                        filename = file.path(output_file,
                                             sprintf("SAT_%s.nc", substr(names(imerg_early_files[[zi]]), 2, 25))),
                        datatype = 'FLT4S', force_v4 = TRUE, compression = 7,
                        overwrite = TRUE)
  })
  
  
})
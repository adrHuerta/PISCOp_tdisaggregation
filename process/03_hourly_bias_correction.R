rm(list = ls())
"%>%" = magrittr::`%>%`


# creating window time range moving
time_range <- seq(as.POSIXct("2015-01-01 00:00:00"), as.POSIXct("2020-12-31 23:00:00"), by = "hour")
window_c = 3 # window moving
dailyVar <- sort(unique(format(time_range, format = "%m-%d %H:%M:%S")))
tail0 <- dailyVar[(length(dailyVar) - window_c + 1):length(dailyVar)]
tail1 <- dailyVar[1:window_c]
dailyVar <- c(tail0, dailyVar, tail1)

# split by chunk
dailyVar <- mapply(function(x, y){
  dailyVar[x:y]
  }, x = 1:8784, y = (window_c*2+1):length(dailyVar), SIMPLIFY = FALSE) 

#
output_file = "data/processed/gridded/mean_SATc"

lapply(1:length(dailyVar), function(i){
  
  time_values <- dailyVar[[i]]
  
  i_aws <- c(sapply(time_values, function(z){list.files("./data/processed/gridded/AWSs", pattern = z, full.names = TRUE)}))
  i_aws <- raster::brick(lapply(i_aws, raster::raster))
  
  i_mean_sat_ts <- c(sapply(time_values, function(z){list.files("./data/processed/gridded/mean_SAT", pattern = z, full.names = TRUE)}))
  i_mean_sat <- raster::brick(lapply(i_mean_sat_ts, raster::raster))
  names(i_mean_sat) <- sapply(i_mean_sat_ts, function(z){strsplit(strsplit(z, "/")[[1]][6], "[.]")[[1]][1]})
  i_mean_sat_to_save = i_mean_sat[[19:24]]
  
  parallel::mclapply(1:raster::ncell(i_aws), function(n_pixel){
    
    if(all(is.na(i_mean_sat[n_pixel]))){
      
      mean_sat_c <- i_mean_sat_to_save[n_pixel]
      
    } else {
      
      MBC::QDM(o.c = i_aws[n_pixel],
               m.c = i_mean_sat[n_pixel],
               m.p = i_mean_sat_to_save[n_pixel], ratio = TRUE, trace = 0.1)$mhat.p -> mean_sat_c
      
    }
    
    as.numeric(round(mean_sat_c, 1))
  }, mc.cores = 12) -> to_set_values
  
  
  for(xxi in 1:raster::nlayers(i_mean_sat_to_save)){
    raster::values(i_mean_sat_to_save[[xxi]]) <- sapply(to_set_values, function(x) x[xxi])  
  }
  

  lapply(1:raster::nlayers(i_mean_sat_to_save), function(zi){
    raster::writeRaster(x = i_mean_sat_to_save[[zi]],
                        varname = "p",
                        filename = file.path(output_file,
                                             sprintf("%s.nc", names(i_mean_sat_to_save[[zi]]))),
                        datatype = 'FLT4S', force_v4 = TRUE, compression = 7)
    })


  })
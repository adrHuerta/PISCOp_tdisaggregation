rm(list = ls())
"%>%" = magrittr::`%>%`

# observed data
aws_data <- readRDS("./data/processed/obs/AWS/AWSs.RDS")

# PISCOp grid
PISCOp_grid <- raster::raster("./data/others/PISCOp_grid_mask.nc")

output_file = "data/processed/gridded/AWSs"

time_step_loop <- data.frame(time = time(aws_data$values),
                             year_month = format(time(aws_data$values), "%Y-%m"))

# interpolation
by(time_step_loop, time_step_loop$year_month, function(x){
  
  x_aws_data_value <- aws_data$values[x$time,]
  
  parallel::mclapply(1:nrow(x_aws_data_value), function(time_step){
    
    xyz_i <- aws_data$xyz
    xyz_i@data$value <- as.numeric(x_aws_data_value[time_step, ])
    xyz_i <- xyz_i[complete.cases(xyz_i@data), ]

    gs <- gstat::gstat(formula = value ~ 1, locations = xyz_i, set = list(idp = 2))
    idw <- round(raster::interpolate(PISCOp_grid, gs), 1)
    idw
  
  }, mc.cores = 10) -> raster_brick_aws
  
  raster::writeRaster(x = raster::brick(raster_brick_aws),
                      filename = file.path(output_file,
                                           sprintf("%s_%s.nc", "AWSs_gridded",  unique(x$year_month))),
                      datatype = 'FLT4S', force_v4 = TRUE, compression = 7)
  
  print(unique(x$year_month))
})









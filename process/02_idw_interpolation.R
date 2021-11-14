rm(list = ls())
"%>%" = magrittr::`%>%`

# observed data
aws_data <- readRDS("./data/processed/obs/AWS/AWSs.RDS")

# PISCOp grid
PISCOp_grid <- raster::raster("./data/others/PISCOp_grid_mask.nc")

output_file = "data/processed/gridded/AWSs"

# interpolation
parallel::mclapply(1:nrow(aws_data$values), function(time_step){
    
    xyz_i <- aws_data$xyz
    xyz_i@data$value <- as.numeric(aws_data$values[time_step, ])
    xyz_i <- xyz_i[complete.cases(xyz_i@data), ]

    gs <- gstat::gstat(formula = value ~ 1, locations = xyz_i, set = list(idp = 2))
    idw <- round(raster::interpolate(PISCOp_grid, gs), 1)
    name_to_save <- format(time(aws_data$values[time_step, ]), "%Y-%m-%d %H:%M:%S")
    
    raster::writeRaster(x = idw,
                        varname = "p",
                        filename = file.path(output_file,
                                             sprintf("%s_%s.nc", "AWSs",  name_to_save)),
                        datatype = 'FLT4S', force_v4 = TRUE, compression = 7)
  
  }, mc.cores = 10)

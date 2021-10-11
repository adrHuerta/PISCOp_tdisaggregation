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

parallel::mclapply(format(time(aws_data), "%Y-%m-%d %H:%M:%S")[1:10], function(step_time){
  
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
    grid_res <- raster::brick(grid_res)[["var1.pred"]]
    grid_res <- (sqrt(step_time_data$covs)*grid_res)^2
  }
  
  
  raster::writeRaster(x = round(grid_res, 1), 
                      filename = file.path(output_path, 
                                           sprintf("%s_satc.nc", step_time)),
                      datatype = 'FLT4S', force_v4 = TRUE, compression = 7)
  
}, mc.cores = 2)


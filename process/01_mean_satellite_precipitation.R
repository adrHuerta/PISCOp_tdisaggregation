rm(list = ls())
"%>%" = magrittr::`%>%`

# gridded satellite data
imerg_early_files <- dir("./data/processed/gridded/IMERG-Early/",
                         full.names = TRUE)[-1] %>%
  lapply(function(x) raster::brick(x))

persiann_css_files <- dir("./data/processed/gridded/PERSIANN-CSS/",
                          full.names = TRUE)[-1] %>%
  lapply(function(x) raster::brick(x))

gsmap_op_files <- dir("./data/processed/gridded/GSMaP_op/",
                          full.names = TRUE)[-1] %>%
  lapply(function(x) raster::brick(x))

# are time the same?
all(sapply(1:length(imerg_early_files), function(x){
  all(imerg_early_files[[x]]@z[[1]] == persiann_css_files[[x]]@z[[1]])
  }))

all(sapply(1:length(imerg_early_files), function(x){
  all(imerg_early_files[[x]]@z[[1]] == gsmap_op_files[[x]]@z[[1]])
}))

#
output_file <- "data/processed/gridded/mean_SAT"

#
for(year in 1:length(imerg_early_files)){
  
  grid_x <- imerg_early_files[[year]]
  grid_y <- persiann_css_files[[year]]
  grid_z <- gsmap_op_files[[year]]
  
  raster::brick(
    parallel::mclapply(1:raster::nlayers(grid_x), function(time_step){
    
    grid_res <- (grid_x[[time_step]] + grid_y[[time_step]] + grid_z[[time_step]])/3
    round(grid_res, 1)
    
  }, mc.cores = 10)
  ) -> raster_brick_aws
  
  raster_brick_aws <- raster::setZ(raster_brick_aws, grid_x@z[[1]], "Date/time")
  
  raster::writeRaster(x = raster_brick_aws,
                      varname = "p",
                      filename = file.path(output_file,
                                           sprintf("%s_%s.nc", "mean_SAT",  substr(grid_x[[1]]@z[[1]], 1, 4))),
                      datatype = 'FLT4S', force_v4 = TRUE, compression = 7)
}





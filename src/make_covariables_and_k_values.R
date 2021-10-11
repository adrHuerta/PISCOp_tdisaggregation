make_covariables <- function(date_time,
                             covs_list,
                             obs_xyz,
                             obs)
{
  #
  covs_data <- raster::brick(covs_list$imerg_early, covs_list$era5_land)
  names(covs_data) <- names(covs_list)
  
  #
  obs_xyz@data$value = as.numeric(obs) 
  obs_data <- obs_xyz[complete.cases(obs_xyz@data), ]
  
  list(covs = covs_data, obs = obs_data)
}

best_k_value <- function(k_range = c(1:10),
                         data_vars)
{
  
  example_ts_point <- raster::extract(data_vars$covs, data_vars$obs, cellnumber = FALSE, sp = TRUE)
  sapply(k_range, function(x){
    tryCatch(mgcv::gam(value ~ s(imerg_early, k = x) + s(era5_land, k = x),
                       data = sqrt(example_ts_point@data[, c(3:5)]),
                       method = "REML",
                       family = "gaussian")$aic,
             error = function(e) NA) 
    
  }) -> aic_values
  k_range[match(min(aic_values, na.rm = TRUE), aic_values)]
  
}

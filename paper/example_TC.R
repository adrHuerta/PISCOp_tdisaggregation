rm(list = ls())
"%>%" = magrittr::`%>%`

library(xts)

# gridded satellite data
imerg_early_files <- dir("./data/processed/gridded/IMERG-Early",
                         full.names = TRUE) %>%
  lapply(function(z){
    raster::brick(z)[5000] %>% as.numeric()
  }) %>% do.call(c, .) %>%
  xts::xts(., seq(as.POSIXct("2015-01-01 00:00:00"), as.POSIXct("2020-12-31 23:00:00"), by = "hour")) #%>%
  #xts::apply.daily(sum)
  
persiann_css_files <- dir("./data/processed/gridded/PERSIANN-CSS/",
                          full.names = TRUE) %>%
  lapply(function(z){
    raster::brick(z)[5000] %>% as.numeric()
  }) %>% do.call(c, .) %>%
  xts::xts(., seq(as.POSIXct("2015-01-01 00:00:00"), as.POSIXct("2020-12-31 23:00:00"), by = "hour")) #%>%
#xts::apply.daily(sum)

gsmap_op_files <- dir("./data/processed/gridded/GSMaP_op/",
                      full.names = TRUE) %>%
  lapply(function(z){
    raster::brick(z)[5000] %>% as.numeric()
  }) %>% do.call(c, .) %>%
  xts::xts(., seq(as.POSIXct("2015-01-01 00:00:00"), as.POSIXct("2020-12-31 23:00:00"), by = "hour")) #%>%
#xts::apply.daily(sum)

########
# applying merging TC by following the work of https://www.researchgate.net/publication/343115933_Precipitation_Merging_Based_on_the_Triple_Collocation_Method_Across_Mainland_China
# applying log-RMSE
# using all time serie

# 1
#r_imerg = log(mean(imerg_early_files)) + (imerg_early_files - mean(imerg_early_files))*(1/mean(imerg_early_files))
r_imerg = log(imerg_early_files + .1)
# 2
#r_persiann = log(mean(persiann_css_files)) + (persiann_css_files - mean(persiann_css_files))*(1/mean(persiann_css_files))
r_persiann = log(persiann_css_files + .1)
# 3
#r_gsmap = log(mean(gsmap_op_files)) + (gsmap_op_files - mean(gsmap_op_files))*(1/mean(gsmap_op_files))
r_gsmap = log(gsmap_op_files + .1)

# C1,1
C_imerg_imerg = sum((r_imerg - mean(r_imerg))*(r_imerg - mean(r_imerg)))/length(r_gsmap)
# C1,2
C_imerg_persiann = sum((r_imerg - mean(r_imerg))*(r_persiann - mean(r_persiann)))/length(r_gsmap)
# C1,3
C_imerg_gsmap = sum((r_imerg - mean(r_imerg))*(r_gsmap - mean(r_gsmap)))/length(r_gsmap)
# C2,3
C_persiann_gsmap = sum((r_persiann - mean(r_persiann))*(r_gsmap - mean(r_gsmap)))/length(r_gsmap)
# C2,2
C_persiann_persiann = sum((r_persiann - mean(r_persiann))*(r_persiann - mean(r_persiann)))/length(r_gsmap)
# C3,3
C_gsmap_gsmap = sum((r_gsmap - mean(r_gsmap))*(r_gsmap - mean(r_gsmap)))/length(r_gsmap)

# rmse
# rmse1
rmse_imerg2 = C_imerg_imerg - (C_imerg_persiann*C_imerg_gsmap)/C_persiann_gsmap
# rmse2
rmse_persiann2 = C_persiann_persiann - (C_imerg_persiann*C_persiann_gsmap)/C_imerg_gsmap
# rmse3
rmse_gsmap2 = C_gsmap_gsmap - (C_imerg_gsmap*C_persiann_gsmap)/C_imerg_persiann

# w
# w1
w_imerg = (rmse_persiann2*rmse_gsmap2)/(rmse_imerg2*rmse_persiann2 + rmse_persiann2*rmse_gsmap2 + rmse_imerg2*rmse_gsmap2)
# w2
w_persiann = (rmse_imerg2*rmse_gsmap2)/(rmse_imerg2*rmse_persiann2 + rmse_persiann2*rmse_gsmap2 + rmse_imerg2*rmse_gsmap2)
# w3
w_gsmap = (rmse_imerg2*rmse_persiann2)/(rmse_imerg2*rmse_persiann2 + rmse_persiann2*rmse_gsmap2 + rmse_imerg2*rmse_gsmap2)

# tc merging
rm = w_imerg*r_imerg + w_persiann*r_persiann + w_gsmap*r_gsmap

# log rm
lattice::xyplot(cbind(rm, r_imerg, r_persiann, r_gsmap))
# log rm -> pp 
lattice::xyplot(round(exp(cbind(rm, r_imerg, r_persiann, r_gsmap))-.1, 1))

# log rm -> pp vs mean 
lattice::xyplot(cbind(round(exp(rm) - .1, 1), 
                      round(apply(cbind(imerg_early_files, persiann_css_files, gsmap_op_files), 1, mean), 1)))
zoo::coredata(cbind(round(exp(rm) - .1, 1), 
                      round(apply(cbind(imerg_early_files, persiann_css_files, gsmap_op_files), 1, mean), 1))) %>% plot(xlab = "TC", ylab = "Promedio")


# applying merging TC by following the work of https://www.researchgate.net/publication/343115933_Precipitation_Merging_Based_on_the_Triple_Collocation_Method_Across_Mainland_China
# applying log-RMSE
# using a chunk by month
# by day neither week does not work good
# creating time range
time_range <- seq(as.POSIXct("2015-01-01 00:00:00"), as.POSIXct("2020-12-31 23:00:00"), by = "hour")
dailyVar <- as.list(sort(unique(format(time_range, format = "%m"))))
#%dailyVar[[59]] <- unlist(dailyVar[59:60])
#dailyVar[[60]] <- NULL

lapply(dailyVar, function(m_d){
  
  # 1
  #r_imerg = log(mean(imerg_early_files)) + (imerg_early_files - mean(imerg_early_files))*(1/mean(imerg_early_files))
  r_imerg = log(imerg_early_files[format(time(imerg_early_files), "%m") %in% m_d] + .1)
  # 2
  #r_persiann = log(mean(persiann_css_files)) + (persiann_css_files - mean(persiann_css_files))*(1/mean(persiann_css_files))
  r_persiann = log(persiann_css_files[format(time(persiann_css_files), "%m") %in% m_d] + .1)
  # 3
  #r_gsmap = log(mean(gsmap_op_files)) + (gsmap_op_files - mean(gsmap_op_files))*(1/mean(gsmap_op_files))
  r_gsmap = log(gsmap_op_files[format(time(gsmap_op_files), "%m") %in% m_d] + .1)
  
  # C1,1
  C_imerg_imerg = sum((r_imerg - mean(r_imerg))*(r_imerg - mean(r_imerg)))/length(r_gsmap)
  # C1,2
  C_imerg_persiann = sum((r_imerg - mean(r_imerg))*(r_persiann - mean(r_persiann)))/length(r_gsmap)
  # C1,3
  C_imerg_gsmap = sum((r_imerg - mean(r_imerg))*(r_gsmap - mean(r_gsmap)))/length(r_gsmap)
  # C2,3
  C_persiann_gsmap = sum((r_persiann - mean(r_persiann))*(r_gsmap - mean(r_gsmap)))/length(r_gsmap)
  # C2,2
  C_persiann_persiann = sum((r_persiann - mean(r_persiann))*(r_persiann - mean(r_persiann)))/length(r_gsmap)
  # C3,3
  C_gsmap_gsmap = sum((r_gsmap - mean(r_gsmap))*(r_gsmap - mean(r_gsmap)))/length(r_gsmap)
  
  # rmse
  # rmse1
  rmse_imerg2 = C_imerg_imerg - ((C_imerg_persiann*C_imerg_gsmap) + .1)/(C_persiann_gsmap + .1)
  # rmse2
  rmse_persiann2 = C_persiann_persiann - ((C_imerg_persiann*C_persiann_gsmap) + .1)/(C_imerg_gsmap + .1)
  # rmse3
  rmse_gsmap2 = C_gsmap_gsmap - ((C_imerg_gsmap*C_persiann_gsmap) + .1)/(C_imerg_persiann + .1)
  
  # w
  # w1
  w_imerg = (rmse_persiann2*rmse_gsmap2)/(rmse_imerg2*rmse_persiann2 + rmse_persiann2*rmse_gsmap2 + rmse_imerg2*rmse_gsmap2)
  # w2
  w_persiann = (rmse_imerg2*rmse_gsmap2)/(rmse_imerg2*rmse_persiann2 + rmse_persiann2*rmse_gsmap2 + rmse_imerg2*rmse_gsmap2)
  # w3
  w_gsmap = (rmse_imerg2*rmse_persiann2)/(rmse_imerg2*rmse_persiann2 + rmse_persiann2*rmse_gsmap2 + rmse_imerg2*rmse_gsmap2)
  
  # tc merging
  rm = w_imerg*r_imerg + w_persiann*r_persiann + w_gsmap*r_gsmap
  cbind(rm, r_imerg, r_persiann, r_gsmap)
  
}) %>% do.call(rbind, .) -> merged_values

# log rm
lattice::xyplot(merged_values)
# log rm -> pp 
lattice::xyplot(round(exp(merged_values)-.1, 1))

# log rm -> pp vs mean 
lattice::xyplot(cbind(round(exp(merged_values$rm) - .1, 1), 
                      round(apply(cbind(imerg_early_files, persiann_css_files, gsmap_op_files), 1, mean), 1)))
zoo::coredata(cbind(round(exp(merged_values$rm) - .1, 1), 
                    round(apply(cbind(imerg_early_files, persiann_css_files, gsmap_op_files), 1, mean), 1))) %>% plot(xlab = "TC", ylab = "Promedio")

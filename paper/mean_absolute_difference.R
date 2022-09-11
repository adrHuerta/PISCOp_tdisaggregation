library(xts)
library(raster)
library(ggplot2)

rm(list = ls())
"%>%" = magrittr::`%>%`

#
shp_sa = file.path(".", "data", "others", "Sudamérica.shp") %>%
  shapefile() %>%
  broom::tidy()

aws <- readRDS("./data/processed/obs/AWS/AWSs.RDS")

# precipitation frequency and intensity plots
aws_sp_vi <- aws$xyz[aws$xyz$LEN >= 50,]
aws_ts_vi <- aws$values[, aws_sp_vi$CODE]

#
id_aws_vi <- raster::extract(raster::raster(dir("data/processed/gridded/PISCOp_h/", full.names = TRUE)[1]),
                             aws_sp_vi, cellnumbers = TRUE)[,1]

piscop_hourly_ts_vi <- dir("data/processed/gridded/PISCOp_h", full.names = TRUE) %>%
  parallel::mclapply(function(x) t(raster::brick(x)[id_aws_vi]), mc.cores = 3) %>%
  do.call(rbind, .) %>%
  xts::xts(., time(aws_ts_vi)) %>%
  setNames(colnames(aws_ts_vi))

piscop_hourly_noBC_ts_vi <- dir("data/processed/gridded/PISCOp_h_non-DBC", full.names = TRUE) %>%
  parallel::mclapply(function(x) t(raster::brick(x)[id_aws_vi]), mc.cores = 3) %>%
  do.call(rbind, .) %>%
  xts::xts(., time(aws_ts_vi)) %>%
  setNames(colnames(aws_ts_vi))

seasons <- list(c("12","01","02"), c("06", "07", "08"))

lapply(seasons, function(z){
  
  sapply(names(aws_ts_vi), function(station){
    
    aws_ts_i <- aws_ts_vi[format(time(aws_ts_vi), "%m") %in% z][, station]
    piscop_hourly_i <- piscop_hourly_ts_vi[format(time(piscop_hourly_ts_vi), "%m") %in% z][, station]
    cbind(aws_ts_i, piscop_hourly_i) %>% zoo::coredata() %>% .[complete.cases(.), ] -> r_i
    r_i %>%  apply(2, function(x){
      res = x[x >= 0.1]
      mean(res, na.rm = TRUE)
    }) -> I_i
    
    MAD <- sum(abs( (r_i[,2]/I_i[2]) - (r_i[,1]/I_i[1]) ))/ nrow(r_i)
    MAD
    
  }) -> MAD_1
  
  sapply(names(aws_ts_vi), function(station){
    
    aws_ts_i <- aws_ts_vi[format(time(aws_ts_vi), "%m") %in% z][, station]
    piscop_hourly_noBC_i <- piscop_hourly_noBC_ts_vi[format(time(piscop_hourly_noBC_ts_vi), "%m") %in% z][, station]
    cbind(aws_ts_i, piscop_hourly_noBC_i) %>% zoo::coredata() %>% .[complete.cases(.), ] -> r_i
    r_i %>%  apply(2, function(x){
      res = x[x >= 0.1]
      mean(res, na.rm = TRUE)
    }) -> I_i
    
    MAD <- sum(abs( (r_i[,2]/I_i[2]) - (r_i[,1]/I_i[1]) ))/ nrow(r_i)
    MAD
    
  }) -> MAD_2
  
  rbind(data.frame(value = MAD_1, as.data.frame(aws_sp_vi)[, c("LAT", "LON")], data = rep("PISCOp_h/AWS", length(MAD_1)), season = rep(paste(z, collapse = "_"), length(MAD_1))),
        data.frame(value = MAD_2, as.data.frame(aws_sp_vi)[, c("LAT", "LON")], data = rep("PISCOp_h_non-DBC/AWS", length(MAD_2)), season = rep(paste(z, collapse = "_"), length(MAD_2)))
  )
  
}) %>% do.call(rbind, .) -> to_plot

to_plot %>% 
  transform(value_cut = cut(value, 
                            breaks = c(-Inf, 0.05, 0.1, 0.15, 0.20, 0.25, Inf),
                            labels = c("0.05]", "(0.05,0.1]", "(0.1,0.15]", "(0.15,0.2]", "(0.2,0.25]", "(0.25"),
                            include.lowest = TRUE)) %>%
  .[complete.cases(.), ] %>%
  ggplot() + 
  geom_point(aes(x = LON, y = LAT, shape = value_cut, colour = value_cut), size = 1.25) + 
  scale_shape_manual(values = c(4, 6, 5, 0, 2, 3)) +
  scale_color_manual(values = c("green", "green", "blue", "blue","red", "red")) +
  facet_grid(data~season) + 
  geom_polygon(data = shp_sa,
               aes(x = long, y = lat, group = group),
               fill = NA, colour = "gray40", size = 0.4) +
  coord_quickmap(expand = c(0, 0), ylim = c(-18.575, 0.1), xlim = c(-81.325, -68.25)) + 
  labs(x = "", y = "") + 
  theme_bw()  +
  theme(axis.ticks = element_blank(),
        axis.text = element_blank(),
        axis.title = element_blank(),
        legend.title=element_blank(),
        plot.margin=unit(c(0,0,0,0), "null")) + 
  facet_grid(data~season, switch = "y")

ggsave(file.path(".", "paper", "output", "Figure_06_MAD.pdf"),
       dpi = 300, scale = 1.5,
       width = 4, height = 3, units = "in")

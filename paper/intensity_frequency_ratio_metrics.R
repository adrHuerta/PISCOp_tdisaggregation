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
id_aws_vi <- raster::extract(raster::raster(dir("data/processed/gridded/PISCOp_hourly/", full.names = TRUE)[1]),
                             aws_sp_vi, cellnumbers = TRUE)[,1]

piscop_hourly_ts_vi <- dir("data/processed/gridded/PISCOp_hourly", full.names = TRUE) %>%
  parallel::mclapply(function(x) t(raster::brick(x)[id_aws_vi]), mc.cores = 3) %>%
  do.call(rbind, .) %>%
  xts::xts(., time(aws_ts_vi)) %>%
  setNames(colnames(aws_ts_vi))

piscop_hourly_noBC_ts_vi <- dir("data/processed/gridded/PISCOp_hourly_mean_SAT", full.names = TRUE) %>%
  parallel::mclapply(function(x) t(raster::brick(x)[id_aws_vi]), mc.cores = 3) %>%
  do.call(rbind, .) %>%
  xts::xts(., time(aws_ts_vi)) %>%
  setNames(colnames(aws_ts_vi))

seasons <- list(c("12","01","02"), c("05", "06", "07"))
lapply(seasons, function(z){
  
  aws_ts_vi[format(time(aws_ts_vi), "%m") %in% z] %>%
    apply(2, function(x){
      res = x[x >= 0.1]
      res = length(res)/length(x)
      res
    }) -> df1
  
  piscop_hourly_ts_vi[format(time(piscop_hourly_ts_vi), "%m") %in% z] %>%
    apply(2, function(x){
      res = x[x >= 0.1]
      res = length(res)/length(x)
      res
    }) -> df2
  
  piscop_hourly_noBC_ts_vi[format(time(piscop_hourly_noBC_ts_vi), "%m") %in% z] %>%
    apply(2, function(x){
      res = x[x >= 0.1]
      res = length(res)/length(x)
      res
    }) -> df3
  
  rbind(data.frame(value = df2/df1, as.data.frame(aws_sp_vi)[, c("LAT", "LON")], CODE = names(df2), data = rep("PISCOp_hourly/AWS", length(df2)), season = rep(paste(z, collapse = "_"), length(df2))),
        data.frame(value = df3/df1, as.data.frame(aws_sp_vi)[, c("LAT", "LON")], CODE = names(df3), data = rep("PISCOp_hourly_noBC/AWS", length(df3)), season = rep(paste(z, collapse = "_"), length(df3)))
        )
  
  }) %>% do.call(rbind, .) -> to_plot

to_plot %>% 
  transform(value_cut = cut(value, 
                            breaks = c(-Inf, 0.5, 0.75, 1, 1.25, 1.5, Inf), 
                            include.lowest = TRUE)) %>%
  .[complete.cases(.), ] %>%
ggplot() + 
  geom_point(aes(x = LON, y = LAT, shape = value_cut, colour = value_cut), size = 2) + 
  scale_shape_manual(values = c(4, 6, 5, 0, 2, 3)) +
  scale_color_manual(values = c("red", "red", "green", "green", "blue", "blue")) +
  facet_grid(data~season) + 
  geom_polygon(data = shp_sa,
               aes(x = long, y = lat, group = group),
               fill = NA, colour = "gray40", size = 0.8) +
  coord_quickmap(expand = c(0, 0), ylim = c(-18.575, 0.1), xlim = c(-81.325, -68.25)) + 
  labs(x = "", y = "") + 
  theme_bw()  +
  theme(axis.ticks = element_blank(),
        axis.text = element_blank(),
        axis.title = element_blank(),
        legend.title=element_blank()) + 
  facet_grid(data~season, switch = "y")

ggsave(file.path(".", "paper", "output", "Fig_frequency_ratio.jpg"),
       dpi = 300, scale = 1,
       width = 7, height = 5, units = "in")

#####

lapply(seasons, function(z){
  
  aws_ts_vi[format(time(aws_ts_vi), "%m") %in% z] %>%
    apply(2, function(x){
      res = x[x >= 0.1]
      mean(res, na.rm = TRUE)
    }) -> Is_1
  
  Ms_1 <- apply(aws_ts_vi[format(time(aws_ts_vi), "%m") %in% z], 2, mean, na.rm = TRUE)
  
  piscop_hourly_ts_vi[format(time(piscop_hourly_ts_vi), "%m") %in% z] %>%
    apply(2, function(x){
      res = x[x >= 0.1]
      mean(res, na.rm = TRUE)
    }) -> Id_2
  
  Md_2 <- apply(piscop_hourly_ts_vi[format(time(piscop_hourly_ts_vi), "%m") %in% z], 2, mean, na.rm = TRUE)
  
  piscop_hourly_noBC_ts_vi[format(time(piscop_hourly_noBC_ts_vi), "%m") %in% z] %>%
    apply(2, function(x){
      res = x[x >= 0.1]
      mean(res, na.rm = TRUE)
    }) -> Id_3
  
  Md_3 <- apply(piscop_hourly_noBC_ts_vi[format(time(piscop_hourly_noBC_ts_vi), "%m") %in% z], 2, mean, na.rm = TRUE)
  
  rbind(data.frame(value = (Id_2/Is_1)/(Md_2/Ms_1), as.data.frame(aws_sp_vi)[, c("LAT", "LON")], CODE = names(Id_2), data = rep("PISCOp_hourly/AWS", length(Id_2)), season = rep(paste(z, collapse = "_"), length(Id_2))),
        data.frame(value = (Id_3/Is_1)/(Md_3/Ms_1), as.data.frame(aws_sp_vi)[, c("LAT", "LON")], CODE = names(Id_3), data = rep("PISCOp_hourly_noBC/AWS", length(Id_3)), season = rep(paste(z, collapse = "_"), length(Id_3)))
  )
  
}) %>% do.call(rbind, .) -> to_plot

to_plot %>% 
  transform(value_cut = cut(value, 
                            breaks = c(-Inf, 0.5, 0.75, 1, 1.25, 1.5, Inf), 
                            include.lowest = TRUE)) %>%
  .[complete.cases(.), ] %>%
  ggplot() + 
  geom_point(aes(x = LON, y = LAT, colour = value_cut, shape = value_cut), size = 2) + 
  scale_shape_manual(values = c(4, 6, 5, 0, 2, 3)) +
  scale_color_manual(values = c("red", "red", "green", "green", "blue", "blue")) +
  facet_grid(data~season) + 
  geom_polygon(data = shp_sa,
               aes(x = long, y = lat, group = group),
               fill = NA, colour = "gray40", size = 0.8) +
  coord_quickmap(expand = c(0, 0), ylim = c(-18.575, 0.1), xlim = c(-81.325, -68.25)) + 
  labs(x = "", y = "") + 
  theme_bw()  +
  theme(axis.ticks = element_blank(),
        axis.text = element_blank(),
        axis.title = element_blank(),
        legend.title=element_blank()) + 
  facet_grid(data~season, switch = "y")

ggsave(file.path(".", "paper", "output", "Fig_intensity_ratio.jpg"),
       dpi = 300, scale = 1,
       width = 7, height = 5, units = "in")

library(xts)
library(raster)
library(ggplot2)

rm(list = ls())
"%>%" = magrittr::`%>%`

aws <- readRDS("./data/processed/obs/AWS/AWSs.RDS")

# time serie plots
aws_sp_vi <- aws$xyz[aws$xyz$LEN_x == 1,]
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

cbind(piscop_hourly_ts_vi[,1], piscop_hourly_noBC_ts_vi[,1], aws_ts_vi[, 1]) %>%
  setNames(c("PISCOp_hourly", "PISCOp_hourly_noBC", "AWS")) %>% 
  .["2017-01-30/2017-02-05"] %>%
  fortify() %>%
  reshape2::melt(., "Index") %>% 
  ggplot() +
  geom_line(aes(x = Index, y = value, colour = variable), size = .75) +
  scale_x_datetime(date_labels = "%Y-%m-%d", date_breaks = "1 days") +
  theme_bw() + labs(x = "", y = "") + theme(axis.title = element_blank(), legend.position = c(0.85, 0.5)) + 
  annotate("text", x = as.POSIXct("2017-01-30 12:00:00"), y = 15, 
           label = aws_sp_vi@data[match(names(piscop_hourly_ts_vi[,1]), aws_sp_vi@data$CODE), ]$ESTACION,
           size = 4) -> p1

cbind(piscop_hourly_ts_vi[,2], piscop_hourly_noBC_ts_vi[,2], aws_ts_vi[, 2]) %>%
  setNames(c("PISCOp_hourly", "PISCOp_hourly_noBC", "AWS")) %>% 
  .["2016-02-01/2016-02-07"] %>%
  fortify() %>%
  reshape2::melt(., "Index") %>% 
  ggplot() +
  geom_line(aes(x = Index, y = value, colour = variable), size = .75) +
  scale_x_datetime(date_labels = "%Y-%m-%d", date_breaks = "1 days") +
  theme_bw() + labs(x = "", y = "") + theme(axis.title = element_blank(), legend.position="none") + 
  annotate("text", x = as.POSIXct("2016-02-01 12:00:00"), y = 6.8, 
           label = aws_sp_vi@data[match(names(piscop_hourly_ts_vi[,2]), aws_sp_vi@data$CODE), ]$ESTACION,
           size = 4) -> p2

cbind(piscop_hourly_ts_vi[,3], piscop_hourly_noBC_ts_vi[,3], aws_ts_vi[, 3]) %>%
  setNames(c("PISCOp_hourly", "PISCOp_hourly_noBC", "AWS")) %>% 
  .["2018-01-15/2018-01-22"] %>%
  fortify() %>%
  reshape2::melt(., "Index") %>% 
  ggplot() +
  geom_line(aes(x = Index, y = value, colour = variable), size = .75) +
  scale_x_datetime(date_labels = "%Y-%m-%d", date_breaks = "1 days") +
  theme_bw() + labs(x = "", y = "") + theme(axis.title = element_blank(), legend.position="none") + 
  annotate("text", x = as.POSIXct("2018-01-15 12:00:00"), y = 0.9, 
           label = aws_sp_vi@data[match(names(piscop_hourly_ts_vi[,3]), aws_sp_vi@data$CODE), ]$ESTACION,
           size = 4) -> p3

cbind(piscop_hourly_ts_vi[,4], piscop_hourly_noBC_ts_vi[,4], aws_ts_vi[, 4]) %>%
  setNames(c("PISCOp_hourly", "PISCOp_hourly_noBC", "AWS")) %>% 
  .["2019-01-24/2019-01-31"] %>%
  fortify() %>%
  reshape2::melt(., "Index") %>% 
  ggplot() +
  geom_line(aes(x = Index, y = value, colour = variable), size = .75) +
  scale_x_datetime(date_labels = "%Y-%m-%d", date_breaks = "1 days") +
  theme_bw() + labs(x = "", y = "") + theme(axis.title = element_blank(), legend.position="none") + 
  annotate("text", x = as.POSIXct("2019-01-24 12:00:00"), y = 15, 
           label = aws_sp_vi@data[match(names(piscop_hourly_ts_vi[,4]), aws_sp_vi@data$CODE), ]$ESTACION,
           size = 4) -> p4

cbind(piscop_hourly_ts_vi[,5], piscop_hourly_noBC_ts_vi[,5], aws_ts_vi[, 5]) %>%
  setNames(c("PISCOp_hourly", "PISCOp_hourly_noBC", "AWS")) %>% 
  .["2017-02-01/2017-02-07"] %>%
  fortify() %>%
  reshape2::melt(., "Index") %>% 
  ggplot() +
  geom_line(aes(x = Index, y = value, colour = variable), size = .75) +
  scale_x_datetime(date_labels = "%Y-%m-%d", date_breaks = "1 days") +
  theme_bw() + labs(x = "", y = "") + theme(axis.title = element_blank(), legend.position="none") + 
  annotate("text", x = as.POSIXct("2017-02-01 12:00:00"), y = 7.5, 
           label = aws_sp_vi@data[match(names(piscop_hourly_ts_vi[,5]), aws_sp_vi@data$CODE), ]$ESTACION,
           size = 4) -> p5


cbind(piscop_hourly_ts_vi[,6], piscop_hourly_noBC_ts_vi[,6], aws_ts_vi[, 6]) %>%
  setNames(c("PISCOp_hourly", "PISCOp_hourly_noBC", "AWS")) %>% 
  .["2020-02-17/2020-02-24"] %>%
  fortify() %>%
  reshape2::melt(., "Index") %>% 
  ggplot() +
  geom_line(aes(x = Index, y = value, colour = variable), size = .75) +
  scale_x_datetime(date_labels = "%Y-%m-%d", date_breaks = "1 days") +
  theme_bw() + labs(x = "", y = "") + theme(axis.title = element_blank(), legend.position="none") + 
  annotate("text", x = as.POSIXct("2020-02-17 12:00:00"), y = 8, 
           label = aws_sp_vi@data[match(names(piscop_hourly_ts_vi[,6]), aws_sp_vi@data$CODE), ]$ESTACION,
           size = 4) -> p6
  

cowplot::plot_grid(p1, p2, p3, p4, p5, p6, ncol = 2, nrow = 3)

ggsave(file.path(".", "paper", "output", "Fig_AWSs_vs_gridded_products_vi.jpg"),
       dpi = 200, scale = 1,
       width = 13, height = 5, units = "in")

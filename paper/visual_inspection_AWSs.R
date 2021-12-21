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

cbind(piscop_hourly_ts_vi[,1], piscop_hourly_noBC_ts_vi[,1], aws_ts_vi[, 1]) %>%
  setNames(c("PISCOp_h", "PISCOp_h_non-DBC", "AWS")) %>% 
  .["2017-01-30/2017-02-03"] %>%
  fortify() %>%
  reshape2::melt(., "Index") %>% 
  ggplot() +
  geom_line(aes(x = Index, y = value, colour = variable), size = .75) +
  scale_x_datetime(date_labels = "%m-%d", date_breaks = "1 days") +
  theme_bw() + labs(x = "", y = "") + 
  theme(axis.title = element_blank(), legend.position="none") + 
  theme(axis.text = element_text(size = 8), axis.title = element_text(size = 8)) + 
  theme(plot.margin=unit(c(0,0,0,0), "null")) + 
  annotate("text", x = as.POSIXct("2017-01-30 12:00:00"), y = 15, 
           label = paste(aws_sp_vi@data[match(names(piscop_hourly_ts_vi[,1]), aws_sp_vi@data$CODE), ]$ESTACION, "2017", sep = "\n"),
           size = 2.75) -> p1

cbind(piscop_hourly_ts_vi[,2], piscop_hourly_noBC_ts_vi[,2], aws_ts_vi[, 2]) %>%
  setNames(c("PISCOp_h", "PISCOp_h_non-DBC", "AWS")) %>% 
  .["2016-02-05/2016-02-10"] %>%
  fortify() %>%
  reshape2::melt(., "Index") %>% 
  ggplot() +
  geom_line(aes(x = Index, y = value, colour = variable), size = .75) +
  scale_x_datetime(date_labels = "%m-%d", date_breaks = "1 days") +
  theme_bw() + labs(x = "", y = "") + theme(axis.title = element_blank(), legend.position="none") + 
  theme(axis.text = element_text(size = 8), axis.title = element_text(size = 8)) + 
  theme(plot.margin=unit(c(0,0,0,0), "null")) + 
  annotate("text", x = as.POSIXct("2016-02-05 12:00:00"), y = 7.25, 
           label = paste(aws_sp_vi@data[match(names(piscop_hourly_ts_vi[,2]), aws_sp_vi@data$CODE), ]$ESTACION, "2016", sep = "\n"),
           size = 2.75) -> p2

cbind(piscop_hourly_ts_vi[,3], piscop_hourly_noBC_ts_vi[,3], aws_ts_vi[, 3]) %>%
  setNames(c("PISCOp_h", "PISCOp_h_non-DBC", "AWS")) %>% 
  .["2018-01-16/2018-01-22"] %>%
  fortify() %>%
  reshape2::melt(., "Index") %>% 
  ggplot() +
  scale_y_continuous(limits = c(0, 2), breaks = seq(0, 2, .5)) + 
  geom_line(aes(x = Index, y = value, colour = variable), size = .75) +
  scale_x_datetime(date_labels = "%m-%d", date_breaks = "1 days") +
  theme_bw() +
  theme(axis.title = element_blank(), legend.position = c(0.5, 0.7)) + 
  theme(legend.title = element_text(size = 9), 
        legend.text = element_text(size = 9)) + 
  theme(legend.key.width = unit(.25, "cm"),
        legend.key.size = unit(0, 'lines'),
        legend.box.background = element_rect(colour = "black")) + labs(x = "", y = "") + 
  theme(axis.text = element_text(size = 8), axis.title = element_text(size = 8)) + 
  theme(plot.margin=unit(c(0,0,0,0), "null")) + 
  annotate("text", x = as.POSIXct("2018-01-16 12:00:00"), y = 1.7, 
           label = paste(aws_sp_vi@data[match(names(piscop_hourly_ts_vi[,3]), aws_sp_vi@data$CODE), ]$ESTACION, "2018", sep = "\n"),
           size = 2.75) -> p3

cbind(piscop_hourly_ts_vi[,4], piscop_hourly_noBC_ts_vi[,4], aws_ts_vi[, 4]) %>%
  setNames(c("PISCOp_h", "PISCOp_h_non-DBC", "AWS")) %>% 
  .["2019-01-26/2019-01-31"] %>%
  fortify() %>%
  reshape2::melt(., "Index") %>% 
  ggplot() +
  scale_y_continuous(limits = c(0, 11), breaks = seq(0, 12, 2)) +
  geom_line(aes(x = Index, y = value, colour = variable), size = .75) +
  scale_x_datetime(date_labels = "%m-%d", date_breaks = "1 days") +
  theme_bw() + labs(x = "", y = "") + theme(axis.title = element_blank(), legend.position="none") + 
  theme(axis.text = element_text(size = 8), axis.title = element_text(size = 8)) + 
  theme(plot.margin=unit(c(0,0,0,0), "null")) + 
  annotate("text", x = as.POSIXct("2019-01-26 12:00:00"), y = 9.5, 
           label = paste(aws_sp_vi@data[match(names(piscop_hourly_ts_vi[,4]), aws_sp_vi@data$CODE), ]$ESTACION, "2019", sep = "\n"),
           size = 2.75) -> p4

cbind(piscop_hourly_ts_vi[,5], piscop_hourly_noBC_ts_vi[,5], aws_ts_vi[, 5]) %>%
  setNames(c("PISCOp_h", "PISCOp_h_non-DBC", "AWS")) %>% 
  .["2017-02-01/2017-02-06"] %>%
  fortify() %>%
  reshape2::melt(., "Index") %>% 
  ggplot() +
  geom_line(aes(x = Index, y = value, colour = variable), size = .75) +
  scale_x_datetime(date_labels = "%m-%d", date_breaks = "1 days") +
  theme_bw() + labs(x = "", y = "") + theme(axis.title = element_blank(), legend.position="none") + 
  theme(axis.text = element_text(size = 8), axis.title = element_text(size = 8)) + 
  theme(plot.margin=unit(c(0,0,0,0), "null")) + 
  annotate("text", x = as.POSIXct("2017-02-01 12:00:00"), y = 6.25, 
           label = paste(aws_sp_vi@data[match(names(piscop_hourly_ts_vi[,5]), aws_sp_vi@data$CODE), ]$ESTACION, "2017", sep = "\n"),
           size = 2.75) -> p5

cbind(piscop_hourly_ts_vi[,6], piscop_hourly_noBC_ts_vi[,6], aws_ts_vi[, 6]) %>%
  setNames(c("PISCOp_h", "PISCOp_h_non-DBC", "AWS")) %>% 
  .["2020-02-18/2020-02-23"] %>%
  fortify() %>%
  reshape2::melt(., "Index") %>% 
  ggplot() +
  geom_line(aes(x = Index, y = value, colour = variable), size = .75) +
  scale_x_datetime(date_labels = "%m-%d", date_breaks = "1 days") +
  theme_bw() + labs(x = "", y = "") + theme(axis.title = element_blank(), legend.position="none") + 
  theme(axis.text = element_text(size = 8), axis.title = element_text(size = 8)) + 
  theme(plot.margin=unit(c(0,0,0,0), "null")) + 
  annotate("text", x = as.POSIXct("2020-02-18 12:00:00"), y = 8, 
           label = paste(aws_sp_vi@data[match(names(piscop_hourly_ts_vi[,6]), aws_sp_vi@data$CODE), ]$ESTACION, "2020", sep = "\n"),
           size = 2.75) -> p6

cowplot::plot_grid(p1, p2, p3, p4, p5, p6, ncol = 2, nrow = 3)

ggsave(file.path(".", "paper", "output", "Figure_03_AWSs_vs_gridded_products_vi.jpg"),
       dpi = 200, scale = 1.75,
       width = 5, height = 2.75, units = "in")

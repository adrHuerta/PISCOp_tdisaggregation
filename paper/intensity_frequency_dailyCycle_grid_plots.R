rm(list = ls())
"%>%" = magrittr::`%>%`

library(ggplot2)
library(raster)

aws_xyz <- readRDS("./data/processed/obs/AWS/AWSs.RDS")$xyz

pointcount <- function(r, pts){
  # make a raster of zeroes like the input
  r2 <- r
  r2[] <- 0
  # get the cell index for each point and make a table:
  counts <- table(raster::cellFromXY(r,pts))
  # fill in the raster with the counts from the cell index:
  r2[as.numeric(names(counts))] <- counts
  return(r2)
}

grid_to_NA <- raster(list.files(path = "./paper/output", pattern = "AWSs_hourly_hourly_cycle_*", full.names = TRUE)[-1][[1]])
grid_to_NA <- pointcount(r = grid_to_NA, pts = aws_xyz)
grid_to_NA[grid_to_NA < 1] <- NA
grid_to_NA[grid_to_NA >= 1] <- 1
#
shp_peru = file.path(".", "data", "others", "Departamentos.shp") %>% 
  shapefile() %>%
  broom::tidy()

shp_lakes = file.path(".", "data", "others", "Lagos_lagunas_Project.shp") %>%
  shapefile() %>%
  .[.@data$are > 100, ] %>%
  broom::tidy()

shp_sa = file.path(".", "data", "others", "Sudamérica.shp") %>%
  shapefile() %>%
  broom::tidy()


# mean intensity

PISCOp_hourly <- list.files(path = "./paper/output", pattern = "PISCOp_hourly_intensity_*",
                            full.names = TRUE) %>%
  lapply(function(x){
    res <- raster::raster(x)
    res <- raster::as.data.frame(res, xy = TRUE)
    res <- res[complete.cases(res), ]
    res$season = paste(strsplit(strsplit(x, "[.]")[[1]][2], "_")[[1]][4:6], collapse = '_')
    res$var = "Intensity"
    res$data = "PISCOp_hourly"
    res
  }) %>% do.call("rbind", .)

PISCOp_hourly_mean_SAT <- list.files(path = "./paper/output", pattern = "PISCOp_hourlymeanSAT_intensity_*",
                                     full.names = TRUE) %>%
  lapply(function(x){
    res <- raster::raster(x)
    res <- raster::as.data.frame(res, xy = TRUE)
    res <- res[complete.cases(res), ]
    res$season = paste(strsplit(strsplit(x, "[.]")[[1]][2], "_")[[1]][4:6], collapse = '_')
    res$var = "Intensity"
    res$data = "PISCOp_hourly_noBC"
    res
  }) %>% do.call("rbind", .)

AWSs_gridded <- list.files(path = "./paper/output", pattern = "AWSs_hourly_intensity_*",
                           full.names = TRUE) %>%
  lapply(function(x){
    res <- raster::raster(x) * grid_to_NA
    names(res) = "p"
    res <- raster::as.data.frame(res, xy = TRUE)
    res <- res[complete.cases(res), ]
    res$season = paste(strsplit(strsplit(x, "[.]")[[1]][2], "_")[[1]][4:6], collapse = '_')
    res$var = "Intensity"
    res$data = "AWSs"
    res
  }) %>% do.call("rbind", .)

to_plot_df <- rbind(PISCOp_hourly, PISCOp_hourly_mean_SAT, AWSs_gridded)
to_plot_df$data <- factor(to_plot_df$data, levels = c("PISCOp_hourly", "PISCOp_hourly_noBC", "AWSs"))
to_plot_df$season <- factor(to_plot_df$season, levels = c("12_01_02", "03_04_05", "06_07_08", "09_10_11"))


ggplot() + 
  geom_raster(data = subset(subset(to_plot_df, var == "Intensity"), data == "PISCOp_hourly"), aes(x = x, y = y, fill = p)) + 
  geom_raster(data = subset(subset(to_plot_df, var == "Intensity"), data == "PISCOp_hourly_noBC"), aes(x = x, y = y, fill = p)) + 
  geom_point(data = subset(subset(to_plot_df, var == "Intensity"), data == "AWSs"), aes(x = x, y = y, fill = p, colour = p), shape = 21, size = 2, show.legend = FALSE) + 
  scale_colour_gradientn(colors = colorRampPalette(ochRe::ochre_palettes$healthy_reef)(100), limits = c(0, 3)) + 
  scale_fill_gradientn(colors = colorRampPalette(ochRe::ochre_palettes$healthy_reef)(100),
                       "Mean hourly precipitation intensity (mm)",
                       limits = c(0, 3),
                       guide = guide_colorbar(frame.colour = "black",
                                              ticks.colour = "black",
                                              title.position = "left",
                                              barheight = 12,
                                              title.theme = element_text(size = 10,
                                                                         angle = 90,
                                                                         vjust = 0.5))) +
  geom_polygon(data = shp_sa,
               aes(x = long, y = lat, group = group),
               fill = NA, colour = "gray40", size = 0.8) +
  coord_quickmap(expand = c(0, 0), ylim = c(-18.575, 0.1), xlim = c(-81.325, -68.25)) + 
  labs(x = "", y = "") + 
  theme_bw()  +
  theme(axis.ticks = element_blank(),
        axis.text = element_blank(),
        axis.title = element_blank()) + 
  facet_grid(data~season, switch = "y")
  
ggsave(file.path(".", "paper", "output", "Fig_mean_intensity.jpg"),
       dpi = 300, scale = 1,
       width = 10, height = 7, units = "in")


# mean frequency 

PISCOp_hourly <- list.files(path = "./paper/output", pattern = "PISCOp_hourly_frequency_*",
                            full.names = TRUE) %>%
  lapply(function(x){
    res <- raster::raster(x)
    res <- raster::as.data.frame(res, xy = TRUE)
    res <- res[complete.cases(res), ]
    res$season = paste(strsplit(strsplit(x, "[.]")[[1]][2], "_")[[1]][5:7], collapse = '_')
    res$value = paste(strsplit(strsplit(x, "[.]")[[1]][2], "_")[[1]][4], collapse = '_')
    res$var = "Frequency"
    res$data = "PISCOp_hourly"
    res
  }) %>% do.call("rbind", .)

PISCOp_hourly_mean_SAT <- list.files(path = "./paper/output", pattern = "PISCOp_hourlymeanSAT_frequency_*",
                                     full.names = TRUE) %>%
  lapply(function(x){
    res <- raster::raster(x)
    res <- raster::as.data.frame(res, xy = TRUE)
    res <- res[complete.cases(res), ]
    res$season = paste(strsplit(strsplit(x, "[.]")[[1]][2], "_")[[1]][5:7], collapse = '_')
    res$value = paste(strsplit(strsplit(x, "[.]")[[1]][2], "_")[[1]][4], collapse = '_')
    res$var = "Frequency"
    res$data = "PISCOp_hourly_noBC"
    res
  }) %>% do.call("rbind", .)

AWSs_gridded <- list.files(path = "./paper/output", pattern = "AWSs_hourly_frequency_*",
                           full.names = TRUE) %>%
  lapply(function(x){
    res <- raster::raster(x) * grid_to_NA
    names(res) = "p"
    res <- raster::as.data.frame(res, xy = TRUE)
    res <- res[complete.cases(res), ]
    res$season = paste(strsplit(strsplit(x, "[.]")[[1]][2], "_")[[1]][5:7], collapse = '_')
    res$value = paste(strsplit(strsplit(x, "[.]")[[1]][2], "_")[[1]][4], collapse = '_')
    res$var = "Frequency"
    res$data = "AWSs"
    res
  }) %>% do.call("rbind", .)

to_plot_df <- rbind(PISCOp_hourly, PISCOp_hourly_mean_SAT, AWSs_gridded)
to_plot_df$data <- factor(to_plot_df$data, levels = c("PISCOp_hourly", "PISCOp_hourly_noBC", "AWSs"))
to_plot_df$season <- factor(to_plot_df$season, levels = c("12_01_02", "06_07_08"))
to_plot_df$value <- factor(to_plot_df$value, levels = c("01", "5"), labels = c("0.1 mm/h", "5 mm/h"))


ggplot() + 
  geom_raster(data = subset(subset(subset(to_plot_df, var == "Frequency"), data == "PISCOp_hourly"), value == "0.1 mm/h"), aes(x = x, y = y, fill = p)) + 
  geom_raster(data = subset(subset(subset(to_plot_df, var == "Frequency"), data == "PISCOp_hourly_noBC"), value == "0.1 mm/h"), aes(x = x, y = y, fill = p)) + 
  geom_point(data = subset(subset(subset(to_plot_df, var == "Frequency"), data == "AWSs"), value == "0.1 mm/h"), aes(x = x, y = y, fill = p, colour = p), shape = 21, size = 2, show.legend = FALSE) + 
  scale_colour_gradientn(colors = colorRampPalette(ochRe::ochre_palettes$healthy_reef)(500), limits = c(0, 50)) + 
  scale_fill_gradientn(colors =  colorRampPalette(ochRe::ochre_palettes$healthy_reef)(500),
                       "Mean frequencies of wet hours (>= 0.1 mm/h, %)",
                       limits = c(0, 50),
                       guide = guide_colorbar(frame.colour = "black",
                                              ticks.colour = "black",
                                              direction = "horizontal",
                                              title.position = "top",
                                              barheight = 1,
                                              barwidth = 13,
                                              title.theme = element_text(size = 9,
                                                                         angle = 0,
                                                                         vjust = 0.5))) +
  geom_polygon(data = shp_sa,
               aes(x = long, y = lat, group = group),
               fill = NA, colour = "gray40", size = 0.8) +
  coord_quickmap(expand = c(0, 0), ylim = c(-18.575, 0.1), xlim = c(-81.325, -68.25)) + 
  labs(x = "", y = "") + 
  theme_bw()  +
  theme(axis.ticks = element_blank(),
        axis.text = element_blank(),
        axis.title = element_blank(),
        legend.position = "bottom") + 
  facet_grid(season ~ data, switch = "y") -> pp_01


ggplot() + 
  geom_raster(data = subset(subset(subset(to_plot_df, var == "Frequency"), data == "PISCOp_hourly"), value == "5 mm/h"), aes(x = x, y = y, fill = p)) + 
  geom_raster(data = subset(subset(subset(to_plot_df, var == "Frequency"), data == "PISCOp_hourly_noBC"), value == "5 mm/h"), aes(x = x, y = y, fill = p)) + 
  geom_point(data = subset(subset(subset(to_plot_df, var == "Frequency"), data == "AWSs"), value == "5 mm/h"), aes(x = x, y = y, fill = p, colour = p), shape = 21, size = 2, show.legend = FALSE) + 
  scale_colour_gradientn(colors = colorRampPalette(ochRe::ochre_palettes$healthy_reef)(500), limits = c(0, 5)) + 
  scale_fill_gradientn(colors =  colorRampPalette(ochRe::ochre_palettes$healthy_reef)(500),
                       "Mean frequencies of wet hours (>= 5 mm/h, %)",
                       limits = c(0, 5),
                       guide = guide_colorbar(frame.colour = "black",
                                              ticks.colour = "black",
                                              direction = "horizontal",
                                              title.position = "top",
                                              barheight = 1,
                                              barwidth = 13,
                                              title.theme = element_text(size = 9,
                                                                         angle = 0,
                                                                         vjust = 0.5))) +
  geom_polygon(data = shp_sa,
               aes(x = long, y = lat, group = group),
               fill = NA, colour = "gray40", size = 0.8) +
  coord_quickmap(expand = c(0, 0), ylim = c(-18.575, 0.1), xlim = c(-81.325, -68.25)) + 
  labs(x = "", y = "") + 
  theme_bw()  +
  theme(axis.ticks = element_blank(),
        axis.text = element_blank(),
        axis.title = element_blank(),
        legend.position = "bottom") + 
  facet_grid(season ~ data, switch = "y") -> pp_02

cowplot::plot_grid(pp_01, pp_02, ncol = 2)

ggsave(file.path(".", "paper", "output", "Fig_mean_frequency.jpg"),
       dpi = 300, scale = 1,
       width = 10, height = 6, units = "in")

# daily cycle

PISCOp_hourly <- list.files(path = "./paper/output", pattern = "PISCOp_hourly_hourly_cycle_*",
                            full.names = TRUE)[-1] %>%
  lapply(function(x){
    res <- raster::raster(x)
    res <- raster::as.data.frame(res, xy = TRUE)
    res <- res[complete.cases(res), ]
    res$season = paste(strsplit(strsplit(x, "[.]")[[1]][2], "_")[[1]][6:10], collapse = '_')
    res$var = strsplit(strsplit(x, "[.]")[[1]][2], "_")[[1]][5]
    res$data = paste(strsplit(strsplit(strsplit(x, "[.]")[[1]][2], "/")[[1]][4], "_")[[1]][1:2], collapse = '_')
    res
  }) %>% do.call("rbind", .)

PISCOp_hourly_mean_SAT <- list.files(path = "./paper/output", pattern = "PISCOp_hourlymeanSAT_hourly_cycle_*",
                            full.names = TRUE)[-1] %>%
  lapply(function(x){
    res <- raster::raster(x)
    res <- raster::as.data.frame(res, xy = TRUE)
    res <- res[complete.cases(res), ]
    res$season = paste(strsplit(strsplit(x, "[.]")[[1]][2], "_")[[1]][6:10], collapse = '_')
    res$var = strsplit(strsplit(x, "[.]")[[1]][2], "_")[[1]][5]
    res$data = "PISCOp_hourly_noBC"
    res
  }) %>% do.call("rbind", .)

AWSs_gridded <- list.files(path = "./paper/output", pattern = "AWSs_hourly_hourly_cycle_*",
                                     full.names = TRUE)[-1] %>%
  lapply(function(x){
    res <- raster::raster(x) * grid_to_NA
    names(res) = "p"
    res <- raster::as.data.frame(res, xy = TRUE)
    res <- res[complete.cases(res), ]
    res$season = paste(strsplit(strsplit(x, "[.]")[[1]][2], "_")[[1]][6:10], collapse = '_')
    res$var = strsplit(strsplit(x, "[.]")[[1]][2], "_")[[1]][5]
    res$data = "AWSs"
    res
  }) %>% do.call("rbind", .)

to_plot_df <- rbind(PISCOp_hourly, PISCOp_hourly_mean_SAT, AWSs_gridded)
to_plot_df$data <- factor(to_plot_df$data, levels = c("PISCOp_hourly", "PISCOp_hourly_noBC", "AWSs"))


  ggplot() + 
  geom_raster(data = subset(subset(to_plot_df, var == "maxvalue"), data == "PISCOp_hourly"), aes(x = x, y = y, fill = p)) + 
  geom_raster(data = subset(subset(to_plot_df, var == "maxvalue"), data == "PISCOp_hourly_noBC"), aes(x = x, y = y, fill = p)) + 
  geom_point(data = subset(subset(to_plot_df, var == "maxvalue"), data == "AWSs"), aes(x = x, y = y, fill = p, colour = p), shape = 21, size = 2, show.legend = FALSE) +
  scale_colour_gradientn(colors = colorRampPalette(ochRe::ochre_palettes$olsen_seq)(100), limits = c(0, 23)) + 
  scale_fill_gradientn(colors = colorRampPalette(ochRe::ochre_palettes$olsen_seq)(100),
                       "Time with max value (hour)",
                       limits = c(0, 23),
                       guide = guide_colorbar(frame.colour = "black",
                                              ticks.colour = "black",
                                              title.position = "left",
                                              barheight = 8,
                                              title.theme = element_text(size = 10,
                                                                         angle = 90,
                                                                         vjust = 0.5))) +
  geom_polygon(data = shp_sa,
               aes(x = long, y = lat, group = group),
               fill = NA, colour = "gray40", size = 0.8) +
  coord_quickmap(expand = c(0, 0), ylim = c(-18.575, 0.1), xlim = c(-81.325, -68.25)) + 
  labs(x = "", y = "") + 
  theme_bw()  +
  theme(axis.ticks = element_blank(),
        axis.text = element_blank(),
        axis.title = element_blank()) +
  facet_grid(~data) -> pp_01

  ggplot() + 
  geom_raster(data = subset(subset(to_plot_df, var == "amplitude"), data == "PISCOp_hourly"), aes(x = x, y = y, fill = p)) + 
  geom_raster(data = subset(subset(to_plot_df, var == "amplitude"), data == "PISCOp_hourly_noBC"), aes(x = x, y = y, fill = p)) +
  geom_point(data = subset(subset(to_plot_df, var == "amplitude"), data == "AWSs"), aes(x = x, y = y, fill = p, colour = p), shape = 21, size = 2, show.legend = FALSE) +
  scale_colour_gradientn(colors = colorRampPalette(ochRe::ochre_palettes$healthy_reef)(100), limits = c(0, 2.5)) + 
  scale_fill_gradientn(colors = colorRampPalette(ochRe::ochre_palettes$healthy_reef)(100),
                       "Maximum amplitude (mm)",
                       limits = c(0, 2.5),
                       guide = guide_colorbar(frame.colour = "black",
                                              ticks.colour = "black",
                                              title.position = "left",
                                              barheight = 8,
                                              title.theme = element_text(size = 10,
                                                                         angle = 90,
                                                                         vjust = 0.5))) +
  geom_polygon(data = shp_sa,
               aes(x = long, y = lat, group = group),
               fill = NA, colour = "gray40", size = 0.8) +
  coord_quickmap(expand = c(0, 0), ylim = c(-18.575, 0.1), xlim = c(-81.325, -68.25)) + 
  labs(x = "", y = "") + 
  theme_bw() +
  theme(axis.ticks = element_blank(),
        axis.text = element_blank(),
        axis.title = element_blank()) +
  facet_grid(~data) -> pp_02


cowplot::plot_grid(pp_01, pp_02, ncol = 1)

ggsave(file.path(".", "paper", "output", "Fig_daily_cycle_mean.jpg"),
       dpi = 300, scale = 1,
       width = 10, height = 6, units = "in")

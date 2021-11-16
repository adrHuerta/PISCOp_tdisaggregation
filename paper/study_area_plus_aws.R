rm(list = ls())
"%>%" = magrittr::`%>%`

library(raster)
library(ggplot2)
library(cowplot)
library(ggrepel)

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

# data
aws <- readRDS("./data/processed/obs/AWS/AWSs.RDS")
piscop <- raster::brick(
  dir("./data/processed/gridded/PISCOpd", full.names = TRUE) %>%
  lapply(function(x) raster::calc(raster::brick(x), mean))
  ) %>% raster::calc(., mean)

p3 <- ggplot() + 
  geom_raster(data = raster::as.data.frame(piscop, xy = TRUE) %>%
                .[complete.cases(.),],
              aes(x = x, y = y, fill = layer), alpha = .8) + 
  scale_fill_gradientn(colors = colorRampPalette(ochRe::ochre_palettes$olsen_seq)(10)[4:10],
                       na.value= "lightblue",
                       "Mean precipitacion (mm/day)",
                       guide = guide_colorbar(frame.colour = "black",
                                              ticks.colour = "black",
                                              title.position = "left",
                                              barheight = 8,
                                              title.theme = element_text(size = 9,
                                                                         angle = 90,
                                                                         vjust = 0.5))) +
  # scale_fill_manual(values = ochre_palettes$williams_pilbara) + 
  geom_polygon(data = shp_peru,
               aes(x = long, y = lat, group = group),
               fill = NA, colour = "gray40", size = 0.5) + 
  geom_polygon(data = shp_sa,
               aes(x = long, y = lat, group = group),
               fill = NA, colour = "gray40", size = 0.8) +
  geom_polygon(data = shp_lakes, # water bodies > 10 km^2
               aes(x = long, y = lat, group = group),
               fill = "lightblue", colour = "lightblue", size = 0.3) +
  geom_point(data = as.data.frame(aws$xyz),
             aes(x = LON, y = LAT), colour = "black", shape = 1, size = 2, stroke = .7) + #f3
  # scale_size_manual("Filtro 3", values = c(3, 1.5)) +
  # scale_colour_manual("Filtro 2", values = c("blue", "red")) +
  # scale_shape_manual("Filtro 1:", values = c(22, 21)) + 
  #scale_color_discrete("Para Bias-Correction:") + 
  # scale_x_continuous(position = "top") + # to be used with the other subplots
  # geom_label_repel(data = df_countries, aes(x = LON, y = LAT, label = label),
  #                  fill = "white", size = 2,
  #                  box.padding = 0.01, alpha = .5) +  
  # geom_label_repel(data = df_chile, aes(x = LON, y = LAT, label = label),
  #                  fill = "white", size = 2,
  #                  box.padding = 0.01, alpha = .5,
#                  min.segment.length = unit(0, 'lines'),
#                  nudge_x = 1, nudge_y = 1) +
coord_quickmap(expand = c(0, 0), ylim = c(-18.575, 0.1), xlim = c(-81.325, -68.25)) + 
  #coord_quickmap(expand = F, ylim = c(-18.5, -15), xlim = c(-77, -72)) + 
  labs(x = "", y = "") +
  #theme_linedraw() + 
  theme_bw() + 
  theme(axis.title = element_text(size = 8.5),
        # axis.title.x = element_text(size = 15),
        # axis.text.x = element_blank(),
        # axis.title.y = element_text(size = 15),
        axis.text.y = element_text(angle = 90),
        legend.box = 'vertical',
        legend.justification = c(0, 0), legend.position = c(0, 0),
        legend.background = element_blank())

ggsave(file.path(".", "paper", "output", "Fig_study_area_stations.jpg"),
       dpi = 300, scale = 1,
       width = 4.5, height = 6, units = "in")
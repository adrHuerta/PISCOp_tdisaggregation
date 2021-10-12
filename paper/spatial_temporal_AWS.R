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
  broom::tidy()

shp_sa = file.path(".", "data", "others", "Sudamérica.shp") %>%
  shapefile() %>%
  broom::tidy()

# obs data
aws_data <- read.csv("data/processed/obs/AWS/AWS_data.csv", stringsAsFactors = FALSE)
aws_data <- xts::xts(aws_data[,-1], as.POSIXct(aws_data[,1]))
aws_xyz <- read.csv("data/processed/obs/AWS/AWS_xyz.csv", stringsAsFactors = FALSE)

lenght_of_data <- xts::xts(apply(aws_data, 1, function(x) sum(!is.na(x))), time(aws_data))
qc01 <- aws_xyz


df_countries <- data.frame(LON = c(-77, -72, -67.5, -67.4),
                           LAT = c(-.65,   0,  -7, -15.6),
                           label = c("Ecuador", "Colombia", "Brazil", "Bolivia"))
df_chile <- data.frame(LON = c(-69.6),
                       LAT = c(-18.4),
                       label = c("Chile"))

p3 <- ggplot() + 
  geom_polygon(data = shp_sa,
               aes(x = long, y = lat, group = group),
               fill = NA, colour = "gray20", size = 0.5) +
  # geom_polygon(data = shp_lakes[shp_lakes@data$are > 10, ], # water bodies > 10 km^2
  #              aes(x = long, y = lat, group = group),
  #              fill = "lightblue", colour = "lightblue", size = 0.3) +
  geom_polygon(data = shp_peru,
               aes(x = long, y = lat, group = group),
               fill = NA, colour = "gray20", size = 0.5) + 
  geom_point(data = qc01,
             aes(x = LON, y = LAT), colour = "blue") + #f3
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
p3


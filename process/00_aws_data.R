library(xts)
rm(list = ls())
"%>%" = magrittr::`%>%`

# obs data
aws_data <- read.csv("data/raw/obs/AWS/AWS_data.csv", stringsAsFactors = FALSE)
aws_data <- xts::xts(aws_data[,-1], as.POSIXct(aws_data[,1]))
aws_data <- aws_data["2015/2020"]
aws_xyz <- read.csv("data/raw/obs/AWS/AWS_xyz.csv", stringsAsFactors = FALSE)

# spatial xyz data
sp_xyz <- sp::SpatialPointsDataFrame(coords = aws_xyz[, c("LON", "LAT")],
                                     data = aws_xyz[, c("CODE", "ESTACION")],
                                     proj4string = sp::CRS("+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0"))

# save
saveRDS(list(values = aws_data, xyz = sp_xyz),
        file = "./data/processed/obs/AWS/AWSs.RDS")

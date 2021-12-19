rm(list = ls())
"%>%" = magrittr::`%>%`

library(raster)
library(xts)

# aws 
aws_data <- read.csv("data/raw/obs/AWS/AWS_non_shifted_data.csv", stringsAsFactors = FALSE)
aws_data <- xts::xts(aws_data[,-1], as.POSIXct(aws_data[,1]))
aws_data <- aws_data["2015/2020"]
length_of_data <- apply(aws_data, 2, function(x){sum(!is.na(x))*100/length(x)})
length_of_data <- length_of_data[length_of_data > 5]
aws_data <- aws_data[, names(length_of_data)]

aws_xyz <- read.csv("data/raw/obs/AWS/AWS_xyz.csv", stringsAsFactors = FALSE)
aws_xyz <- aws_xyz[match(names(length_of_data), aws_xyz$CODE), ]
aws_xyz$LEN <- length_of_data
aws_xyz$LEN_x <- 0
aws_xyz[match(c(names(length_of_data[length_of_data >= 90][c(-c(2, 5))]), "X4727547C", "X47E2D1CC"), aws_xyz$CODE),]$LEN_x <- 1
row.names(aws_xyz) <- NULL

aws_xyz$CODE == colnames(aws_data)

# points - pixel
aws_point_pixel <- raster::extract(raster::brick(dir("data/processed/gridded/PISCOpd", full.names = TRUE)[1])[[1]] + 0,
                                   aws_xyz[, c("LON", "LAT")],
                                   cellnumbers = TRUE)[,1]

# PISCOp
PISCOpd_data <- dir("data/processed/gridded/PISCOpd", full.names = TRUE) %>%
  lapply(function(x) t(raster::brick(x)[aws_point_pixel])) %>%
  do.call(rbind, .) %>%
  xts::xts(., seq(as.Date("2014-01-01"), as.Date("2020-12-31"), by = "day")) %>%
  setNames(colnames(aws_data)) %>%
  .["2015/2020"]

size_of_lag = seq(-24, 24, by = 1) 
size_of_lag_res = list()

for(n in 1:length(size_of_lag)){
  print(n)
  hobo_daily <- aws_data %>%
    lapply(function(z){
      xts::lag.xts(z, k = size_of_lag[n]) %>%
        xts::apply.daily(sum, na.rm = FALSE)
    }) %>%
    do.call(cbind, .)
  
  time(hobo_daily) <- as.Date(format(time(hobo_daily), "%Y-%m-%d"))
  
  lapply(1:ncol(PISCOpd_data), function(zz){
    
    cor(x = zoo::coredata(PISCOpd_data)[, zz], 
        y = zoo::coredata(hobo_daily)[, zz], 
        use = "pairwise.complete.obs", method = "spearman")
    
  }) %>% unlist() -> res
  size_of_lag_res[[n]] <- data.frame(res)
  
}

do.call(cbind, size_of_lag_res) %>%
  setNames(size_of_lag) -> res

jpeg(file = "paper/output/aws2daily.jpg", width = 1700, height = 800, res = 150)
boxplot(res, ylab = "R (spearman)", xlab = "lag (hour)")
dev.off()
which.max(apply(res, 2, mean, na.rm = TRUE)) # lag == -8 (best R)

# comparing python lag with r lag

# aws shifted (used)
aws_shifted_data <- read.csv("data/raw/obs/AWS/AWS_data.csv", stringsAsFactors = FALSE)
aws_shifted_data <- xts::xts(aws_shifted_data[,-1], as.POSIXct(aws_shifted_data[,1]))
aws_shifted_data <- aws_shifted_data["2015/2020"]
length_of_data <- apply(aws_shifted_data, 2, function(x){sum(!is.na(x))*100/length(x)})
length_of_data <- length_of_data[length_of_data > 5]
aws_shifted_data <- aws_shifted_data[, names(length_of_data)]

colnames(aws_shifted_data) == colnames(aws_data)


lapply(1:ncol(aws_shifted_data), function(zz){
  
  cor(x = xts::lag.xts(zoo::coredata(aws_data)[, zz], k =-8), 
      y = zoo::coredata(aws_shifted_data)[, zz], 
      use = "pairwise.complete.obs", method = "spearman")
  
}) %>% unlist() %>% boxplot() # the same

# adr <- aws_data[1:50, 100]
# zoo::coredata(adr) <- c(0:23, 0:23, 0, 1)
# cbind(xts::lag.xts(adr, k =-8), adr) %>% View()
rm(list = ls())
"%>%" = magrittr::`%>%`

data.frame(Product = c("IMERG-Early", "PERSIANN-CSS", "GSMaP_NRT"),
           Timespan = c("2000/06 - Present", "2003/01 - Present","2000/03 - Present"),
           Version = c("6B","1","6"),
           Spatial_coverage = c("60°N - 60°S","60°N - 60°S","60°N - 60°S"),
           Temporal_resolution = c("Half hourly","Hourly","Hourly"),
           Spatial_resolution = c("0.1° x 0.1°","0.04° x 0.04°","0.1° x 0.1°"),
           Source = c("https://jsimpsonhttps.pps.eosdis.nasa.gov/imerg/gis/early/","https://chrsdata.eng.uci.edu/","https://developers.google.com/earth-engine/datasets/catalog/JAXA_GPM_L3_GSMaP_v6_operational")) %>%
  write.csv("./paper/output/sat_Table.csv", row.names = FALSE)

# https://sharaku.eorc.jaxa.jp/GSMaP/faq/GSMaP_faq06.html
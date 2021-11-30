O_IDW <- function(formula_i, 
                  location_i, 
                  grid_i,
                  idpR = seq(0.8, 3.5, 0.1))
{
  
  idpRange <- idpR
  mse <- rep(NA, length(idpRange))
  for (i in 1:length(idpRange)) {
    mse[i] <- mean(gstat::krige.cv(formula = formula_i, locations = location_i, nfold = nrow(location_i),
                                   nmax = Inf, set = list(idp = idpRange[i]), verbose = F)$residual^2)
  }
  
  poss <- which(mse %in% min(mse))
  bestparam <- idpRange[poss]
  
  gs <- gstat::gstat(formula = formula_i, locations = location_i, set = list(idp = bestparam))
  idw <- round(raster::interpolate(grid_i, gs), 1)
  idw
  
}
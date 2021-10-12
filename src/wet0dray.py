def wetOdray(grid_imerg_daily, grid_pisco_daily, grid_hourly):
    if (np.isnan(grid_imerg_daily)) or (np.isnan(grid_pisco_daily)):
        return np.nan
    elif (grid_imerg_daily > 0) and (grid_pisco_daily <= 0):
        return 0
    elif (grid_imerg_daily > 0) and (grid_pisco_daily > 0):
        return grid_hourly/grid_imerg_daily
    elif (grid_imerg_daily <= 0) and (grid_pisco_daily <= 0):
        return 0
    elif (grid_imerg_daily <= 0) and (grid_pisco_daily > 0):
        return 1/24

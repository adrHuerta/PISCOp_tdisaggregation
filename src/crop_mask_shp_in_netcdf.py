def xr_crop(shp_i, netcdf_i):
  
  # get box
  box_i = shp_i.total_bounds
  
  # crop based on box
  crop_netcdf_i = netcdf_i.where((netcdf_i["longitude"] > box_i[0]) & # min lon
                                 (netcdf_i["longitude"] < box_i[2]) & # max lon
                                 (netcdf_i["latitude"] > box_i[1]) & # min lat
                                 (netcdf_i["latitude"] < box_i[3]), # max lat
                                 drop = True)
  
  return crop_netcdf_i



def xr_shp_to_grid(shp_i, netcdf_array):

  # get real box
  shp_i_geometry = shp_i.geometry

  # adding crs
  mask = netcdf_array.rio.set_crs(shp_i.crs)

  # "rasterizing"
  mask = mask.rio.clip(shp_i_geometry, drop = False)

  # making "True/False" values
  mask.values[~np_isnan(mask.values)] = 1

  return mask.drop(["time"])


def xr_mask(grid_mask, netcdf_i):

  # masking
  mask_netcdf_i = netcdf_i.where(grid_mask == True)

  return mask_netcdf_i

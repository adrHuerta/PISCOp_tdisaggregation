library(gstat)

autofitVariogramPISCOp <- function (formula, input_data, model = c("Sph", "Exp", "Gau", 
                                                                   "Ste"), kappa = c(0.05, seq(0.2, 2, 0.1), 5, 10), fix.values = c(NA, 
                                                                                                                                    NA, NA), verbose = FALSE, GLS.model = NA, start_vals = c(NA, 
                                                                                                                                                                                             NA, NA), miscFitOptions = list(), boundaries, ...) 
{
  if ("alpha" %in% names(list(...))) 
    warning("Anisotropic variogram model fitting not supported, see the documentation of autofitVariogram for more details.")
  miscFitOptionsDefaults = list(merge.small.bins = TRUE, min.np.bin = 5)
  miscFitOptions = modifyList(miscFitOptionsDefaults, miscFitOptions)
  longlat = !is.projected(input_data)
  if (is.na(longlat)) 
    longlat = FALSE
  diagonal = spDists(t(bbox(input_data)), longlat = longlat)[1, 
                                                             2]
  if (!missing(boundaries)) 
    boundaries = boundaries
  else {
    boundaries = c(2, 4, 6, 9, 12, 15, 25, 35, 50, 65, 80, 
                   100) * diagonal * 0.35/100
  }
  if (!is(GLS.model, "variogramModel")) {
    experimental_variogram = variogram(formula, input_data, 
                                       boundaries = boundaries, ...)
  }
  else {
    if (verbose) 
      cat("Calculating GLS sample variogram\n")
    g = gstat(NULL, "bla", formula, input_data, model = GLS.model, 
              set = list(gls = 1))
    experimental_variogram = variogram(g, boundaries = boundaries, 
                                       ...)
  }
  if (miscFitOptions[["merge.small.bins"]]) {
    if (verbose) 
      cat("Checking if any bins have less than 5 points, merging bins when necessary...\n\n")
    while (TRUE) {
      if (length(experimental_variogram$np[experimental_variogram$np < 
                                           miscFitOptions[["min.np.bin"]]]) == 0 | length(boundaries) == 
          1) 
        break
      boundaries = boundaries[2:length(boundaries)]
      if (!is(GLS.model, "variogramModel")) {
        experimental_variogram = variogram(formula, 
                                           input_data, boundaries = boundaries, ...)
      }
      else {
        experimental_variogram = variogram(g, boundaries = boundaries, 
                                           ...)
      }
    }
  }
  if (is.na(start_vals[1])) {
    initial_nugget = min(experimental_variogram$gamma)
  }
  else {
    initial_nugget = start_vals[1]
  }
  if (is.na(start_vals[2])) {
    initial_range = 0.1 * diagonal
  }
  else {
    initial_range = start_vals[2]
  }
  if (is.na(start_vals[3])) {
    initial_sill = mean(c(max(experimental_variogram$gamma), 
                          median(experimental_variogram$gamma)))
  }
  else {
    initial_sill = start_vals[3]
  }
  if (!is.na(fix.values[1])) {
    fit_nugget = FALSE
    initial_nugget = fix.values[1]
  }
  else fit_nugget = TRUE
  if (!is.na(fix.values[2])) {
    fit_range = FALSE
    initial_range = fix.values[2]
  }
  else fit_range = TRUE
  if (!is.na(fix.values[3])) {
    fit_sill = FALSE
    initial_sill = fix.values[3]
  }
  else fit_sill = TRUE
  getModel = function(psill, model, range, kappa, nugget, 
                      fit_range, fit_sill, fit_nugget, verbose) {
    if (verbose) 
      debug.level = 1
    else debug.level = 0
    if (model == "Pow") {
      warning("Using the power model is at your own risk, read the docs of autofitVariogram for more details.")
      if (is.na(start_vals[1])) 
        nugget = 0
      if (is.na(start_vals[2])) 
        range = 1
      if (is.na(start_vals[3])) 
        sill = 1
    }
    obj = try(fit.variogram(experimental_variogram, model = vgm(psill = psill, 
                                                                model = model, range = range, nugget = nugget, kappa = kappa), 
                            fit.ranges = c(fit_range), fit.sills = c(fit_nugget, 
                                                                     fit_sill), debug.level = 0), TRUE)
    if ("try-error" %in% class(obj)) {
      warning("An error has occured during variogram fitting. Used:\n", 
              "\tnugget:\t", nugget, "\n\tmodel:\t", model, 
              "\n\tpsill:\t", psill, "\n\trange:\t", range, 
              "\n\tkappa:\t", ifelse(kappa == 0, NA, kappa), 
              "\n  as initial guess. This particular variogram fit is not taken into account. \nGstat error:\n", 
              obj)
      return(NULL)
    }
    else return(obj)
  }
  test_models = model
  SSerr_list = c()
  vgm_list = list()
  counter = 1
  for (m in test_models) {
    if (m != "Mat" && m != "Ste") {
      model_fit = getModel(initial_sill - initial_nugget, 
                           m, initial_range, kappa = 0, initial_nugget, 
                           fit_range, fit_sill, fit_nugget, verbose = verbose)
      if (!is.null(model_fit)) {
        vgm_list[[counter]] = model_fit
        SSerr_list = c(SSerr_list, attr(model_fit, "SSErr"))
      }
      counter = counter + 1
    }
    else {
      for (k in kappa) {
        model_fit = getModel(initial_sill - initial_nugget, 
                             m, initial_range, k, initial_nugget, fit_range, 
                             fit_sill, fit_nugget, verbose = verbose)
        if (!is.null(model_fit)) {
          vgm_list[[counter]] = model_fit
          SSerr_list = c(SSerr_list, attr(model_fit, 
                                          "SSErr"))
        }
        counter = counter + 1
      }
    }
  }
  strange_entries = sapply(vgm_list, function(v) any(c(v$psill, 
                                                       v$range) < 0) | is.null(v))
  if (any(strange_entries)) {
    if (verbose) {
      print(vgm_list[strange_entries])
      cat("^^^ ABOVE MODELS WERE REMOVED ^^^\n\n")
    }
    warning("Some models where removed for being either NULL or having a negative sill/range/nugget, \n\tset verbose == TRUE for more information")
    SSerr_list = SSerr_list[!strange_entries]
    vgm_list = vgm_list[!strange_entries]
  }
  if (verbose) {
    cat("Selected:\n")
    print(vgm_list[[which.min(SSerr_list)]])
    cat("\nTested models, best first:\n")
    tested = data.frame(`Tested models` = sapply(vgm_list, 
                                                 function(x) as.character(x[2, 1])), kappa = sapply(vgm_list, 
                                                                                                    function(x) as.character(x[2, 4])), SSerror = SSerr_list)
    tested = tested[order(tested$SSerror), ]
    print(tested)
  }
  result = list(exp_var = experimental_variogram, var_model = vgm_list[[which.min(SSerr_list)]], 
                sserr = min(SSerr_list))
  class(result) = c("autofitVariogram", "list")
  return(result)
}
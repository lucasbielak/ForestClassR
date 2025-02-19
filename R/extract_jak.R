extract_jak <- function(las_data) {
  features <- data.table(
    eigenvalue_sum = las_data@data$eigenvalue_sum,
    omnivariance = las_data@data$omnivariance,
    eigenentropy = las_data@data$eigenentropy,
    anisotropy = las_data@data$anisotropy,
    planarity = las_data@data$planarity,
    linearity = las_data@data$linearity,
    PCA1 = las_data@data$PCA1,
    PCA2 = las_data@data$PCA2,
    surface_variation = las_data@data$surface_variation,
    sphericity = las_data@data$sphericity,
    verticality = las_data@data$verticality,
    nx = las_data@data$nx,
    ny = las_data@data$ny,
    nz = las_data@data$nz
  )

  if ("label" %in% names(las_data@data)) {
    features[, class := las_data@data$label]
  }

  return(features)
}

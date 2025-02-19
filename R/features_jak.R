features_jak <- function(las_data, radius) {
  # Setup jakteristics
  jak <- import("jakteristics")
  np <- import("numpy")

  # Extract points from LAS data
  points <- data.frame(
    X = las_data@data$X,
    Y = las_data@data$Y,
    Z = las_data@data$Z
  )

  # Convert to numpy array
  points_array <- np$array(as.matrix(points))

  # Calculate features using jakteristics
  features <- jak$compute_features(
    points = points_array,
    search_radius = radius,
    feature_names = c(
      "eigenvalue_sum",
      "omnivariance",
      "eigenentropy",
      "anisotropy",
      "planarity",
      "linearity",
      "PCA1",
      "PCA2",
      "surface_variation",
      "sphericity",
      "verticality",
      "nx",
      "ny",
      "nz"
    ),
  )

  features_df <- as.data.frame(features)
  names(features_df) <- c(
    "eigenvalue_sum",
    "omnivariance",
    "eigenentropy",
    "anisotropy",
    "planarity",
    "linearity",
    "PCA1",
    "PCA2",
    "surface_variation",
    "sphericity",
    "verticality",
    "Nx",
    "Ny",
    "Nz"
  )

  #append eigenvalues to the las
  las_data@data$eigenvalue_sum <- features_df$eigenvalue_sum
  las_data@data$omnivariance <- features_df$omnivariance
  las_data@data$eigenentropy <- features_df$eigenentropy
  las_data@data$anisotropy <- features_df$anisotropy
  las_data@data$planarity <- features_df$planarity
  las_data@data$linearity <- features_df$linearity
  las_data@data$PCA1 <- features_df$PCA1
  las_data@data$PCA2 <- features_df$PCA2
  las_data@data$surface_variation <- features_df$surface_variation
  las_data@data$sphericity <- features_df$sphericity
  las_data@data$verticality <- features_df$verticality
  las_data@data$nx <- features_df$Nx
  las_data@data$ny <- features_df$Ny
  las_data@data$nz <- features_df$Nz

  return(las_data)
}

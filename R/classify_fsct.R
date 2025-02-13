# === R/segment.R ===
#' Run FSCT Segmentation
#'
#' Performs forest scene segmentation on a LAS object using FSCT.
#'
#' @param las LAS object. Input point cloud data
#' @param temp_dir Character. Directory for temporary files (default: tempdir())
#' @param output_name Character. Name for output file (default: "segmented.las")
#' @return LAS object with segmentation labels
#' @export
#' @examples
#' \dontrun{
#' las <- readLAS("sample.las")
#' segmented <- run_fsct(las)
#' }
run_fsct <- function(las, temp_dir = tempdir(), output_name = "segmented.las") {
  if (!inherits(las, "LAS")) {
    stop("Input must be a LAS object")
  }

  # Ensure Python environment is ready
  if (!py_module_available("numpy")) {
    stop("Python environment not properly set up. Please run setup_fsct() first.")
  }

  # Create temporary directory
  if (!dir.exists(temp_dir)) {
    dir.create(temp_dir, recursive = TRUE)
  }

  # Load Python script
  run_path <- system.file("python/run.py", package = "ForestClassR")
  if (!file.exists(run_path)) {
    stop("run.py not found in package installation")
  }

  source_python(run_path)

  # Process LAS file
  temp_las_path <- file.path(temp_dir, "temp_input.las")
  xyz <- data.frame(
    X = las@data$X,
    Y = las@data$Y,
    Z = las@data$Z
  )

  writeLAS(LAS(xyz), temp_las_path)

  # Run segmentation
  tryCatch({
    message("Running FSCT segmentation...")
    run_fsct(temp_las_path)  # Note: This should match the function name in run.py

    fsct_output_dir <- file.path(temp_dir, "temp_input_FSCT_output")
    fsct_output_path <- file.path(fsct_output_dir, "segmented.las")

    if (!file.exists(fsct_output_path)) {
      stop("Segmentation failed: output file not found")
    }

    segmented_las <- readLAS(fsct_output_path)

    # Cleanup
    unlink(temp_las_path)
    unlink(fsct_output_dir, recursive = TRUE)

    message("Segmentation completed successfully!")
    return(segmented_las)
  }, error = function(e) {
    unlink(temp_las_path)
    unlink(file.path(temp_dir, "temp_input_FSCT_output"), recursive = TRUE)
    stop("Segmentation failed: ", e$message)
  })
}

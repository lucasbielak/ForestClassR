#' Open Example Script
#'
#' Opens an example script from the package for easy access.
#'
#' @param example_name The name of the example script (without ".R").
#' @return Opens the example script in RStudio or the system's default editor.
#' @examples
#' open_example("classification_example")
#' @export
open_example <- function(example_name) {
  file_name <- paste0(example_name, ".R") # Append .R extension
  file_path <- system.file("examples", file_name, package = "ForestClassR")

  if (file_path == "") {
    stop("Example not found. Check the name or ensure the example exists in inst/examples/")
  }

  # Open file in RStudio if available, otherwise use system editor
  if (interactive()) {
    if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
      rstudioapi::navigateToFile(file_path)
    } else {
      file.edit(file_path)
    }
  } else {
    message("Example file path: ", file_path)
  }
}

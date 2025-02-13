# === R/setup.R ===
#' Setup FSCT Environment
#'
#' Sets up the Python virtual environment and installs required dependencies for FSCT.
#'
#' @param envname Character. Name of the virtual environment (default: "fsct")
#' @param python_version Character. Python version to use (default: "3.9")
#' @param force Logical. Whether to force recreation of existing environment (default: FALSE)
#' @return Logical indicating successful setup
#' @export
#' @examples
#' \dontrun{
#' setup_fsct()
#' }
setup_env <- function(envname = "ForestClassR", python_version = "3.9", force = FALSE) {
  # Ensure required packages are installed
  if (!requireNamespace("reticulate", quietly = TRUE)) {
    install.packages("reticulate")
  }
  if (!requireNamespace("lidR", quietly = TRUE)) {
    install.packages("lidR")
  }

  # Load required packages
  library(reticulate)
  library(lidR)

  # Check Python installation
  tryCatch({
    python_path <- file.path(Sys.getenv("USERPROFILE"), "Documents",".virtualenvs", envname, "Scripts", "python.exe")
    if (is.null(python_path)) {
      message("Python not found. Installing Python ", python_version, "...")
      reticulate::install_python(version = python_version)
    } else {
      message("Found Python at: ", python_path)
    }
  }, error = function(e) {
    stop("Failed to setup Python: ", e$message)
  })

  # Handle virtual environment
  requirements_path <- system.file("python/requirements.txt", package = "ForestClassR")
  if (!file.exists(requirements_path)) {
    stop("requirements.txt not found in package installation")
  }

  if (virtualenv_exists(envname) && !force) {
    message("Using existing virtual environment: ", envname)
    python_path <- file.path(Sys.getenv("USERPROFILE"),"Documents", ".virtualenvs", envname, "Scripts", "python.exe")
    use_python(python_path, required = TRUE)
  } else {
    if (virtualenv_exists(envname)) {
      message("Removing existing environment...")
      virtualenv_remove(envname)
    }
    message("Creating new virtual environment: ", envname)
    virtualenv_create(envname, python = python_version)
  }

  # Activate environment and install dependencies
  use_virtualenv(envname, required = TRUE)
  message("Installing dependencies...")
  tryCatch({
    virtualenv_install(envname, requirements = requirements_path)
    message("Dependencies installed successfully!")
  }, error = function(e) {
    stop("Failed to install dependencies: ", e$message)
  })

  # Verify installation
  if (py_module_available("numpy") && py_module_available("scipy")) {
    message("Environment setup completed successfully!")
    return(TRUE)
  } else {
    warning("Environment setup completed but some core modules may be missing.")
    return(FALSE)
  }
}

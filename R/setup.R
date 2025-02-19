setup_env <- function(envname = "ForestClassR", python_version = "3.9", force = FALSE) {
  # Ensure required packages are installed
  if (!requireNamespace("reticulate", quietly = TRUE)) {
    install.packages("reticulate")
  }
  if (!requireNamespace("lidR", quietly = TRUE)) {
    install.packages("lidR")
  }

  # Function to check Python version
  check_python_version <- function(python_path, required_version) {
    if (!file.exists(python_path)) {
      return(FALSE)
    }

    # Get Python version
    if (.Platform$OS.type == "windows") {
      version_cmd <- sprintf('"%s" -c "import sys; print(sys.version.split()[0])"', python_path)
    } else {
      version_cmd <- sprintf('%s -c "import sys; print(sys.version.split()[0])"', python_path)
    }
    current_version <- try(system(version_cmd, intern = TRUE), silent = TRUE)

    if (inherits(current_version, "try-error")) {
      return(FALSE)
    }

    # Compare versions
    current_parts <- as.numeric(strsplit(current_version, "\\.")[[1]])
    required_parts <- as.numeric(strsplit(required_version, "\\.")[[1]])

    # Compare major and minor versions
    return(current_parts[1] == required_parts[1] &&
             current_parts[2] == required_parts[2])
  }

  # Function to find Python in common installation locations
  find_python <- function(version) {
    # Initialize empty vector for possible locations
    possible_locations <- character(0)

    if (.Platform$OS.type == "windows") {
      # Windows locations
      possible_locations <- c(
        file.path(Sys.getenv("LOCALAPPDATA"), "Programs", "Python",
                  sprintf("Python%s%s", gsub("\\.", "", version), ""),
                  "python.exe"),
        file.path(Sys.getenv("PROGRAMFILES"), "Python",
                  sprintf("Python%s%s", gsub("\\.", "", version), ""),
                  "python.exe"),
        file.path(Sys.getenv("PROGRAMFILES(X86)"), "Python",
                  sprintf("Python%s%s", gsub("\\.", "", version), ""),
                  "python.exe"),
        file.path(Sys.getenv("USERPROFILE"), "Anaconda3", "python.exe"),
        file.path(Sys.getenv("USERPROFILE"), "miniconda3", "python.exe")
      )
    } else {
      # Linux/Unix locations
      possible_locations <- c(
        # Common system locations
        file.path("/usr/bin", sprintf("python%s", version)),
        file.path("/usr/local/bin", sprintf("python%s", version)),
        # Version-specific locations
        file.path("/usr/bin", sprintf("python%s", gsub("\\.", "", version))),
        # User installations
        file.path(Sys.getenv("HOME"), ".local", "bin", sprintf("python%s", version)),
        # Anaconda/Miniconda locations
        file.path(Sys.getenv("HOME"), "anaconda3", "bin", "python"),
        file.path(Sys.getenv("HOME"), "miniconda3", "bin", "python"),
        # pyenv locations
        file.path(Sys.getenv("HOME"), ".pyenv", "versions", version, "bin", "python"),
        # Custom compiled Python
        file.path("/opt/python", version, "bin", "python")
      )
    }

    # Check each location
    for (loc in possible_locations) {
      if (check_python_version(loc, version)) {
        return(loc)
      }
    }

    return(NULL)
  }

  # Get appropriate path separator and virtual environment path
  path_sep <- .Platform$file.sep
  if (.Platform$OS.type == "windows") {
    venv_base <- file.path(Sys.getenv("USERPROFILE"), "Documents", ".virtualenvs")
    python_exe <- "python.exe"
    scripts_dir <- "Scripts"
  } else {
    venv_base <- file.path(Sys.getenv("HOME"), ".virtualenvs")
    python_exe <- "python"
    scripts_dir <- "bin"
  }

  # Check Python installation
  tryCatch({
    # First check the virtual environment location
    python_path <- file.path(venv_base, envname, scripts_dir, python_exe)

    if (!check_python_version(python_path, python_version)) {
      message("Python ", python_version, " not found in virtual environment.")

      # Check system PATH
      system_python <- Sys.which("python")
      if (system_python != "" && check_python_version(system_python, python_version)) {
        message("Found Python ", python_version, " in system PATH: ", system_python)
        python_path <- system_python
      } else {
        # Search common installation locations
        found_python <- find_python(python_version)
        if (!is.null(found_python)) {
          message("Found Python ", python_version, " at: ", found_python)
          python_path <- found_python
        } else {
          # Prompt user for Python installation
          response <- readline(sprintf(
            "Python %s is required but not found. Would you like to install it? (yes/no): ",
            python_version
          ))

          if (tolower(response) == "yes") {
            message("Installing Python ", python_version, "...")
            tryCatch({
              reticulate::install_python(version = python_version)
              message("Python installation completed successfully.")
            }, error = function(e) {
              stop("Failed to install Python automatically. ",
                   "Please install Python ", python_version,
                   " manually from https://www.python.org/downloads/")
            })
          } else {
            stop("Python ", python_version, " is required to continue. ",
                 "Please install it manually from https://www.python.org/downloads/")
          }
        }
      }
    } else {
      message("Found Python ", python_version, " at: ", python_path)
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
    python_path <- file.path(venv_base, envname, scripts_dir, python_exe)
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

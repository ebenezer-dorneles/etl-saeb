#tests/testthat/test-unzip.R

#' @description Unzip the microdata for the 2025 school census
#' @param input_zip The path to the ZIP file
#' @param output_dir The directory to save the unzipped data
#' @return The output directory
unzip_microdata <- function(zip_path, dest_dir) {
  if (missing(zip_path)) {
    stop("Please provide the path to the ZIP file.")
  }
  
  if (!file.exists(zip_path)) {
    stop("The ZIP file does not exist.")
  }

  if (missing(dest_dir)) {
    stop("Please provide the path to the output directory.")
  }

  file_name <- fs::path_file(zip_path)
  message_success <- glue::glue("✅ {file_name} unzipped successfully!")

  if (dir.exists(dest_dir) && length(fs::dir_ls(dest_dir)) > 0) {
    message(paste0("\n", message_success, "\n"))
    return(invisible(dest_dir))
  }

  utils::unzip(zip_path, exdir = dest_dir)
  file.remove(zip_path)
  
  message(message_success)
  return(invisible(dest_dir))
}

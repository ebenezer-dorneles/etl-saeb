source(here::here("R/utils/download_microdata.R"))

test_that("early return if target directory contains files", {
  tmp_dir <- tempfile("dl_test_")
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE))
  
  # Create a dummy file in the directory
  dummy_file <- file.path(tmp_dir, "dummy.txt")
  writeLines("hello", dummy_file)
  
  dest_file <- file.path(tmp_dir, "downloaded.zip")
  
  # Calling download_microdata with invalid URL should succeed and return early
  # because the target directory contains files
  expect_message(
    result <- download_microdata("http://invalid-url-domain.xxx", dest_file),
    "downloaded.zip downloaded successfully!"
  )
  
  expect_equal(result, dest_file)
})

test_that("creates parent directory when missing", {
  tmp_parent <- tempfile("parent_")
  dest_file <- file.path(tmp_parent, "subdir", "downloaded.zip")
  on.exit(unlink(tmp_parent, recursive = TRUE))
  
  # Evaluating download_microdata should attempt to create the parent directory
  # even if the download fails due to invalid URL
  expect_error(
    download_microdata("https://invalid-domain-name-testing.org", dest_file, time_limit = 1)
  )
  
  expect_true(dir.exists(file.path(tmp_parent, "subdir")))
})

test_that("throws error on invalid URL", {
  tmp_dir <- tempfile("dl_err_")
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE))
  
  dest_file <- file.path(tmp_dir, "target.zip")
  
  expect_error(
    download_microdata("https://this-is-an-invalid-url-for-sure-12345.com", dest_file, time_limit = 2)
  )
})

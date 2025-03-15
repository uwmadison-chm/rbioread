#' Skips the test if bioread isn't available on the platform

skip_if_no_bioread <- function() {
  if (!requireNamespace("reticulate", quietly = TRUE)) {
    testthat::skip("reticulate is not available")
  }
  if (!reticulate::py_module_available("bioread")) {
    testthat::skip("bioread is not available")
  }
}

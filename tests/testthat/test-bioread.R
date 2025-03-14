test_that("acq_read works with example file", {
  acq_file = system.file("extdata", "physio-5.0.1-c.acq", package = "bioread")
  acq_data = bioread::read_acq(acq_file)
  expect_length(acq_data$channels, 4)
})

test_that("acq_read with channel loads only some data", {
  acq_file = system.file("extdata", "physio-5.0.1-c.acq", package = "bioread")
  acq_data = bioread::read_acq(acq_file, channel_indexes = c(1))
  expect_gt(length(acq_data$channels[[1]]$data), 0)
  expect_null(acq_data$channels[[2]]$data)
})

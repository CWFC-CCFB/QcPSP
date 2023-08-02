#'
#' A series of simple tests
#'

test_that("Testing nb rows in QcPlotIndex", {expect_equal(nrow(QcPSP::QcPlotIndex), 12816)})
test_that("Testing nb rows in QcTreeIndex", {expect_equal(nrow(QcPSP::QcTreeIndex), 814232)})
test_that("Testing nb rows in QcMeasurementIndex", {expect_equal(nrow(QcPSP::QcMeasurementIndex), 50430)})
test_that("Testing nb rows in QcTreeMeasurements", {expect_equal(nrow(QcPSP::QcTreeMeasurements), 2089280)})

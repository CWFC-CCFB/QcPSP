#'
#' A series of simple tests
#'

restoreQcPSPData()

test_that("Testing nb rows in QcPlotIndex", {expect_equal(nrow(QcPlotIndex), 12816)})
test_that("Testing nb rows in QcTreeIndex", {expect_equal(nrow(QcTreeIndex), 814232)})
test_that("Testing nb rows in QcMeasurementIndex", {expect_equal(nrow(QcMeasurementIndex), 50430)})
test_that("Testing nb rows in QcTreeMeasurements", {expect_equal(nrow(QcTreeMeasurements), 2089280)})

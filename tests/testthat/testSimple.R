#'
#' A series of simple tests
#'

restoreQcPSPData()

test_that("Testing nb rows in QcPlotIndex", {expect_equal(nrow(QcPlotIndex), 12816)})
test_that("Testing nb rows in QcTreeIndex", {expect_equal(nrow(QcTreeIndex), 814232)})
test_that("Testing nb rows in QcMeasurementIndex", {expect_equal(nrow(QcMeasurementIndex), 50430)})
test_that("Testing nb rows in QcTreeMeasurements", {expect_equal(nrow(QcTreeMeasurements), 2089280)})
test_that("Testing nb rows in QcSaplingMeasurements", {expect_equal(nrow(QcSaplingMeasurements), 223475)})

test_that("Testing nb rows in metadata of QcPlotIndex", {expect_equal(nrow(getMetaData(QcPlotIndex)), 17)})
test_that("Testing nb rows in metadata of QcTreeIndex", {expect_equal(nrow(getMetaData(QcTreeIndex)), 9)})
test_that("Testing nb rows in metadata of QcMeasurementIndex", {expect_equal(nrow(getMetaData(QcMeasurementIndex)), 12)})
test_that("Testing nb rows in metadata of QcTreeMeasurements", {expect_equal(nrow(getMetaData(QcTreeMeasurements)), 9)})
test_that("Testing nb rows in metadata of QcSaplingMeasurements", {expect_equal(nrow(getMetaData(QcSaplingMeasurements)), 4)})


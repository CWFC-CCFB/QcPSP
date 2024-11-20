#'
#' A series of simple tests
#'

restoreQcPSPData()

test_that("Testing nb rows in plots table", {expect_equal(nrow(QcPSP$plots), 12816)})
test_that("Testing nb rows in treeIndex table", {expect_equal(nrow(QcPSP$treeIndex), 814232)})
test_that("Testing nb rows in plotMeasurements table", {expect_equal(nrow(QcPSP$plotMeasurements), 50430)})
test_that("Testing nb rows in treeMeasurements table", {expect_equal(nrow(QcPSP$treeMeasurements), 2089280)})
test_that("Testing nb rows in saplings table", {expect_equal(nrow(QcPSP$saplings), 223475)})
test_that("Testing nb rows in sbwDefoliations table", {expect_equal(nrow(QcPSP$sbwDefoliations), 12816)})
test_that("Testing nb rows in photoInterpretedStands table", {expect_equal(nrow(QcPSP$photoInterpretedStands), 51083)})



test_that("Testing nb rows in metadata of plots table", {expect_equal(nrow(getMetaData("plots")), 17)})
test_that("Testing nb rows in metadata of treeIndex table", {expect_equal(nrow(getMetaData("treeIndex")), 9)})
test_that("Testing nb rows in metadata of plotMeasurements table", {expect_equal(nrow(getMetaData("plotMeasurements")), 12)})
test_that("Testing nb rows in metadata of treeMeasurements table", {expect_equal(nrow(getMetaData("treeMeasurements")), 9)})
test_that("Testing nb rows in metadata of saplings table", {expect_equal(nrow(getMetaData("saplings")), 4)})
test_that("Testing nb rows in metadata of sbwDefoliations table", {expect_equal(nrow(getMetaData("sbwDefoliations")), 2)})


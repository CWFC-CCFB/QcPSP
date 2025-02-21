#'
#' A series of simple tests
#'

restoreQcPSPData()

test_that("Testing nb rows in plots table", {expect_equal(nrow(QcPSPData$plots), 12816)})
test_that("Testing nb rows in treeIndex table", {expect_equal(nrow(QcPSPData$treeIndex), 814232)})
test_that("Testing nb rows in plotMeasurements table", {expect_equal(nrow(QcPSPData$plotMeasurements), 50430)})
test_that("Testing nb rows in treeMeasurements table", {expect_equal(nrow(QcPSPData$treeMeasurements), 2089280)})
test_that("Testing nb rows in saplings table", {expect_equal(nrow(QcPSPData$saplings), 223475)})
test_that("Testing nb rows in sbwDefoliations table", {expect_equal(nrow(QcPSPData$sbwDefoliations), 12816)})
test_that("Testing nb rows in photoInterpretedStands table", {expect_equal(nrow(QcPSPData$photoInterpretedStands), 51083)})



test_that("Testing nb rows in metadata of plots table", {expect_equal(nrow(getMetaData("plots")), 17)})
test_that("Testing nb rows in metadata of treeIndex table", {expect_equal(nrow(getMetaData("treeIndex")), 9)})
test_that("Testing nb rows in metadata of plotMeasurements table", {expect_equal(nrow(getMetaData("plotMeasurements")), 12)})
test_that("Testing nb rows in metadata of treeMeasurements table", {expect_equal(nrow(getMetaData("treeMeasurements")), 9)})
test_that("Testing nb rows in metadata of saplings table", {expect_equal(nrow(getMetaData("saplings")), 4)})
test_that("Testing nb rows in metadata of sbwDefoliations table", {expect_equal(nrow(getMetaData("sbwDefoliations")), 2)})

listPlotMes <- QcPSPData$plotMeasurements[1:10, "ID_PE_MES"]
sample <- QcPSP::extractArtemis2009FormatFromPSPForMetaModelling(QcPSPData, listPlotMes)
#table(sample$SPECIES, useNA = "always")
test_that("Testing nb rows in Artemis-2009 sample", {expect_equal(nrow(sample), 313)})

out <- tryCatch(
  {
    QcPSP::extractArtemis2009FormatFromPSPForMetaModelling(QcPSPData,119600902)
    FALSE
  },
  error = function(cond) {
    TRUE
  }
)
test_that("An error has been returned when no measurement matches those of the list_ID_PE_MES argument",
          {expect_equal(out, TRUE)})




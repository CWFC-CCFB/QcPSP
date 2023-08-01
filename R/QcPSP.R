########################################################
# Clean database from PSP data.
# Author: Mathieu Fortin, Canadian Wood Fibre Centre
# Date: August 2023
########################################################

.welcomeMessage <- function() {
  packageStartupMessage("Welcome to QcPSP!")
  packageStartupMessage("The QcPSP package provides a clean version of the PSP data from the Province of Quebec.")
}


.onAttach <- function(libname, pkgname) {
  .welcomeMessage()
}

.onUnload <- function(libpath) {
}

.onDetach <- function(libpath) {
}


#'
#' A data.frame object containing the plot-level information.
#'
#' @docType data
#'
#' @usage data(plotIndex)
#'
#' @keywords datasets
#'
#' @examples
#' QcPlotIndex <- QcPSP::plotIndex
"plotIndex"

#'
#' A data.frame object containing the tree-level information.
#'
#' @docType data
#'
#' @usage data(treeIndex)
#'
#' @keywords datasets
#'
#' @examples
#' QcTreeIndex <- QcPSP::treeIndex
"treeIndex"

#'
#' A data.frame object containing the tree:measurement information.
#'
#' @docType data
#'
#' @usage data(correctedTreeMeasurements)
#'
#' @keywords datasets
#'
#' @examples
#' QcTreeMeasurements <- QcPSP::correctedTreeMeasurements
"correctedTreeMeasurements"

#'
#' A data.frame object containing the plot:measurement information.
#'
#' @docType data
#'
#' @usage data(measurementIndex)
#'
#' @keywords datasets
#'
#' @examples
#' QcMeasurementIndex <- QcPSP::measurementIndex
"measurementIndex"


#'
#' Restore Quebec PSP data in the global environment
#'
#' @export
restoreQcPSPData <- function() {
  assign("QcPlotIndex", QcPSP::plotIndex, envir = .GlobalEnv)
  assign("QcTreeIndex", QcPSP::treeIndex, envir = .GlobalEnv)
  assign("QcMeasurementIndex", QcPSP::measurementIndex, envir = .GlobalEnv)
  assign("QcTreeMeasurements", QcPSP::correctedTreeMeasurements, envir = .GlobalEnv)
}

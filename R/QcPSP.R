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
#' @usage data(QcPlotIndex)
#'
#' @keywords datasets
#'
#' @examples
#' data(QcPlotIndex)
"QcPlotIndex"

#'
#' A data.frame object containing the tree-level information.
#'
#' @docType data
#'
#' @usage data(QcTreeIndex)
#'
#' @keywords datasets
#'
#' @examples
#' data(QcTreeIndex)
"QcTreeIndex"

#'
#' A data.frame object containing the tree:measurement information.
#'
#' @docType data
#'
#' @usage data(QcTreeMeasurements)
#'
#' @keywords datasets
#'
#' @examples
#' data(QcTreeMeasurements)
"QcTreeMeasurements"

#'
#' A data.frame object containing the plot:measurement information.
#'
#' @docType data
#'
#' @usage data(QcMeasurementIndex)
#'
#' @keywords datasets
#'
#' @examples
#' data(QcMeasurementIndex)
"QcMeasurementIndex"


#'
#' Restore Quebec PSP data in the global environment
#'
#' @export
restoreQcPSPData <- function() {
  assign("QcPlotIndex", QcPSP::QcPlotIndex, envir = .GlobalEnv)
  assign("QcTreeIndex", QcPSP::QcTreeIndex, envir = .GlobalEnv)
  assign("QcMeasurementIndex", QcPSP::QcMeasurementIndex, envir = .GlobalEnv)
  assign("QcTreeMeasurements", QcPSP::QcTreeMeasurements, envir = .GlobalEnv)
}

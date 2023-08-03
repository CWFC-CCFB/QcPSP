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


.loadPackageData <- function(filename) {
  return(readRDS(system.file(paste0("extdata/",filename,".Rds"), package = "QcPSP")))
}

#'
#' Restore Quebec PSP Data in the Global Environment.
#'
#' @description This function call creates four data.frame objects that contain
#' the tree measurements.
#'
#' @details
#'
#' The five data.frame objects are: \cr
#' \itemize{
#' \item QcPlotIndex: the index of the plots \cr
#' \item QcTreeIndex: the index of the trees \cr
#' \item QcMeasurementIndex: the index of the plot measurements \cr
#' \item QcTreeMeasurements: the tree measurements \cr
#' }
#'
#' @export
restoreQcPSPData <- function() {
  assign("QcPlotIndex", .loadPackageData("QcPlotIndex"), envir = .GlobalEnv)
  assign("QcTreeIndex", .loadPackageData("QcTreeIndex"), envir = .GlobalEnv)
  assign("QcMeasurementIndex", .loadPackageData("QcMeasurementIndex"), envir = .GlobalEnv)
  assign("QcTreeMeasurements", .loadPackageData("QcTreeMeasurements"), envir = .GlobalEnv)
}




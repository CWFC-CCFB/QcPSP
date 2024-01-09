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


#'
#' Provide the metadata for any of the four data.frame objects
#'
#' @param dFrame a data.frame object. Any of these four: QcPlotIndex, QcTreeIndex, QcMeasurementIndex, or QcTreeMeasurements
#' @return a data.frame object containing the metadata.
#'
#' @export
getMetaData <- function(dFrame) {
  if (is(dFrame, "character")) {
    objectName <- dFrame
  } else {
    objectName <- deparse(substitute(dFrame))
  }
  if (objectName == "QcPlotIndex") {
    fieldNames <- c("ID_PE", "newID_PE", "nbMeasurementsAfterFiltering",
                    "minYearAfterFiltering", "maxYearAfterFiltering", "latitudeDeg",
                    "longitudeDeg", "elevationM", "regEco",
                    "EcoType", "pentePerc", "drainageCl",
                    "penteCl", "depot", "exposition",
                    "pH_humus", "nonMissingValues")
    description <- c("Original PSP identifier before plot filtering and correction.",
                     "PSP identifier after plot filtering and correction.",
                     "Number of measurements after filtering and correction.",
                     "Date (yr) of initial measurement.",
                     "Date (yr) of latest measurement.",
                     "Latitude (degree).",
                     "Longitude (degree).",
                     "Elevation (m).",
                     "Ecological region code. See tab REG_ECO in file DICTIONNAIRE_PLACETTE.xlsx.",
                     "Ecological type code. See tab TYPE_ECOLOGIQUE in file DICTIONNAIRE_PLACETTE.xlsx.",
                     "Slope inclination (%).",
                     "Drainage class. See tab CLASSE_DE_DRAINAGE in file DICTIONNAIRE_PLACETTE.xlsx.",
                     "Slope class. See tab CLASSE_DE_PENTE in file DICTIONNAIRE_PLACETTE.xlsx.",
                     "Soil type code. See tab DEPOT_DE_SURFACE in file DICTIONNAIRE_PLACETTE.xlsx." ,
                     "Aspect (degree).",
                     "Humus pH.",
                     "A binary variable to indicates that there is no missing information at the plot level.")
    return(data.frame(Field = fieldNames, Description = description))
  } else if (objectName == "QcMeasurementIndex") {
    fieldNames <- c("newID_PE", "k", "ID_PE_MES", "ID_PE", "year", "NO_MES", "ORIGINE", "PERTURB",
                    "DATE_SOND", "newNO_MES", "N_xxx", "G_xxx")
    description <- c("PSP identifier after plot filtering and correction. Link to table QcPlotIndex.",
                     "Measurement index after filtering and correction.",
                     "Measurement identifier which is the concatenation of the fields ID_PE and NO_MES.",
                     "Original PSP identifier before plot filtering and correction.",
                     "Date (yr) of plot measurement.",
                     "Original measurement identifier for this plot (e.g. 1, 2, 3).",
                     "Stand-replacement disturbance code. See tab PERTURBATION in file DICTIONNAIRE_PLACETTE.xlsx.",
                     "Partial disturbance code. See tab PERTURBATION in file DICTIONNAIRE_PLACETTE.xlsx.",
                     "Exact measurement date (YY-MM-DD).",
                     "Measurement identifier after plot filtering and correction.",
                     "Stem density (trees/ha) of species xxx. TOT stands for all-species density. For species code, see tab ESSENCES in file DICTIONNAIRE_PLACETTE.xlsx.",
                     "Basal area (m^2/ha) of species xxx. TOT stands for all-species basal area. For species code, see tab ESSENCES in file DICTIONNAIRE_PLACETTE.xlsx.")
    return(data.frame(Field = fieldNames, Description = description))
  } else if (objectName == "QcTreeIndex") {
    fieldNames <- c("newID_PE", "j", "NO_ARBRE", "ESSENCE", "nbMeasurements", "minYear",
                    "maxYear", "IN_1410", "intruder")
    description <- c("PSP identifier after plot filtering and correction. Link to table QcPlotIndex.",
                     "Tree index after filtering and correction.",
                     "Original tree index.",
                     "Species code. See tab ESSENCES in file DICTIONNAIRE_PLACETTE.xlsx.",
                     "Number of measurements for this tree.",
                     "Initial measurement date (yr).",
                     "Latest measurement date (yr).",
                     "A location identifier for trees with DBH > 31 cm. O: The tree is part of the outer circle of the 14.10-m radius plot.",
                     "A boolean. True if the tree is an intruder.")
    return(data.frame(Field = fieldNames, Description = description))
  } else if (objectName == "QcTreeMeasurements") {
    fieldNames <- c("j", "k", "ETAT", "dbhCm", "hauteurM", "BAL", "NIVLECTAGE", "AGE", "SOURCE_AGE")
    description <- c("Tree index after filtering and correction. Link to table QcTreeIndex.",
                     "Measurement index after filtering and correction. Link to table QcMeasurementIndex.",
                     "Tree status code. See tab ETAT in file DICTIONNAIRE_PLACETTE.xlsx.",
                     "Diameter at breast height (cm).",
                     "Tree height (m).",
                     "Basal area (m2/ha) of trees with DBH larger than the subject.",
                     "Height (cm) along the bole at which tree age was measured.",
                     "Tree age",
                     "Additional information on how tree age was measured. See tab SOURCE_AGE in file DICTIONNAIRE_PLACETTE.xlsx.")
    return(data.frame(Field = fieldNames, Description = description))
  } else {
    warning("Expecting any of these four data.frame objects: QcPlotIndex, QcTreeIndex, QcMeasurementIndex, or QcTreeMeasurements!")
  }
}







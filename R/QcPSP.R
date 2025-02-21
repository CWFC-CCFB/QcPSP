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
#' @description This function call creates a list called QcPSPData in
#' the global environment.
#'
#' @details
#'
#' Ths list contains five data.frame objects: \cr
#' \itemize{
#' \item plots: the index of the plots \cr
#' \item treeIndex: the index of the trees \cr
#' \item plotMeasurements: the index of the plot measurements \cr
#' \item treeMeasurements: the tree measurements \cr
#' \item saplings: the tally of the sapling in the 40 m2 subplot \cr
#' \item sbwDefoliations : the spruce budworm defoliation indices for the plot \cr
#' \item photoInterpretedStands: the photo interpreted stand around the plot \cr
#' }
#'
#' @export
restoreQcPSPData <- function() {
  assign("QcPSPData", .loadPackageData("QcPSP"), envir = .GlobalEnv)
}


#'
#' Provide the metadata for any of the seven data.frame objects
#'
#' @param tableName a string among these six: plots, plotMeasurements, treeIndex,
#' treeMeasurements, saplings, and sbwDefoliations
#'
#' @return a data.frame object containing the metadata.
#'
#' @export
getMetaData <- function(tableName) {
  if (tableName == "plots") {
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
  } else if (tableName == "plotMeasurements") {
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
  } else if (tableName == "treeIndex") {
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
  } else if (tableName == "treeMeasurements") {
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
  } else if (tableName == "saplings") {
    fieldNames <- c("k", "ESSENCE", "CL_DHP", "NB_TIGE")
    description <- c("Measurement index after filtering and correction. Link to table QcMeasurementIndex.",
                     "Species code. See tab ESSENCES in file DICTIONNAIRE_PLACETTE.xlsx.",
                     "Class of DBH (cm). Those are 2-cm diameter class. The value denotes the median.",
                     "Number of saplings tallied in the 40 m2 subplot.")
    return(data.frame(Field = fieldNames, Description = description))
  } else if (tableName == "sbwDefoliations") {
    fieldNames <- c("newID_PE", "d1968")
    description <- c("PSP identifier after plot filtering and correction. Link to table QcPlotIndex.",
                     "The field name contains the year. The field contains the values 0 (no defoliation), 1 (light defoliation), 2 (moderate defoliation), or 3 (severe defoliation)")
    return(data.frame(Field = fieldNames, Description = description))
  } else {
    warning("Expecting any of these six character strings: plots, plotMeasurements, treeIndex, treeMeasurements, sbwDefoliations, or saplings!")
  }
}

#'
#' Extract plot list for Artemis-2009 simulation
#' @param QcPSPData the database that is retrieved through the restoreQcPSPData
#' function
#' @param list_ID_PE_MES a vector of numerics that stand for the ID_PE_MES. The
#' ID_PE_MES field is found in the plotMeasurements data.frame of the
#' database.
#' @return a data.frame object formatted for Capsis simulation
#'
#' @export
extractArtemis2009FormatFromPSPForMetaModelling <- function(QcPSPData, list_ID_PE_MES) {
  plotList <- unique(list_ID_PE_MES) ### make sure there is no duplicate
  mesInfo <- QcPSPData$plotMeasurements[which(QcPSPData$plotMeasurements$ID_PE_MES %in% plotList), c("ID_PE", "k", "ID_PE_MES", "DATE_SOND")]
  if (nrow(mesInfo) == 0) {
    stop("None of ID_PE_MES has been found in the plotMeasurements table!")
  }
  plotInfo <- merge(QcPSPData$plots[, c("ID_PE", "latitudeDeg", "longitudeDeg", "elevationM", "regEco", "EcoType", "drainageCl")],
                    mesInfo,
                    by ="ID_PE") ### SDOMAIN might be missing...
  standInfo <- QcPSPData$photoInterpretedStands[which(QcPSPData$photoInterpretedStands$ID_PE_MES %in% plotList), c("ID_PE_MES", "CL_AGE", "TYPE_ECO")]
  colnames(standInfo)[3] <- "TYPE_ECO_PHOTO"

  treeInfo <- merge(QcPSPData$treeIndex[which(!QcPSPData$treeIndex$intruder), c("j", "ESSENCE", "IN_1410")],
                    QcPSPData$treeMeasurements[which(QcPSPData$treeMeasurements$k %in% plotInfo$k), c("j", "k", "ETAT", "dbhCm", "hauteurM")],
                    by = "j")

  treeInfo <- treeInfo[which(!treeInfo$ETAT  %in% c("GA", "GM", "GV") & !is.na(treeInfo$ESSENCE)),] # removing statuses GA, GM, and GV as well as missing species

  # treeInfo <- merge(QcPSPData$treeIndex[which(!QcPSPData$treeIndex$intruder), c("j", "ESSENCE", "IN_1410")],
  #                   QcPSPData$treeMeasurements[which(QcPSPData$treeMeasurements$k %in% plotInfo$k), c("j", "k", "ETAT", "dbhCm", "hauteurM")],
  #                   by = "j")
  treeInfo$NB_TIGE <- 1
  treeInfo[which(treeInfo$IN_1410 == "O"), "NB_TIGE"] <- 16/25

  saplings <- QcPSPData$saplings[which(QcPSPData$saplings$k %in% plotInfo$k),]
  colnames(saplings)[which(colnames(saplings) == "CL_DHP")] <- "dbhCm"
  saplings$hauteurM <- NA
  saplings$ETAT <- "10"
  saplings$NB_TIGE <- saplings$NB_TIGE * 10
  treeInfo <- rbind(treeInfo[,c("k", "ESSENCE", "ETAT", "dbhCm", "hauteurM", "NB_TIGE")], saplings)
  plotInfo <- merge(plotInfo, standInfo, by = "ID_PE_MES")
  output <- merge(plotInfo, treeInfo, by = "k")
  outputPlots <- unique(output$ID_PE_MES)

  missingPlots <- setdiff(plotList, outputPlots)
  if (length(missingPlots) > 0) {
    message("These plots have no saplings and no trees: ", paste(missingPlots, collapse = ", "))
    message("We will add a fake sapling to make sure they are properly imported in Artemis-2009.")
    fakeSaplings <- NULL
    for (mPlot in missingPlots) {
      fakeSaplings <- rbind(fakeSaplings, data.frame(ID_PE_MES = mPlot, ESSENCE = "SAB", ETAT = "14", dbhCm = as.integer(2), hauteurM = NA, NB_TIGE = 25))
    }
    output_MissingSaplings <- merge(plotInfo,
                                    fakeSaplings,
                                    by = "ID_PE_MES")
    output <- rbind(output, output_MissingSaplings)
  }

  outputPlots <- unique(output$ID_PE_MES)
  missingPlots <- setdiff(plotList, outputPlots)
  if (length(missingPlots) > 0) {
    stop("Apparently, there are still some plots with no saplings and no trees: ", paste(missingPlots, collapse = ", "))
  }

  output <- output[order(output$k, -output$dbhCm),]
  output$ANNEE_SOND <- as.integer(format(output$DATE_SOND, "%Y"))

  output <- output[,c("ID_PE_MES", "latitudeDeg", "longitudeDeg", "elevationM", "regEco", "EcoType", "drainageCl",
                      "ESSENCE", "ETAT", "dbhCm", "NB_TIGE", "hauteurM", "ANNEE_SOND", "TYPE_ECO_PHOTO", "CL_AGE")]
  colnames(output) <- c("PLOT", "LATITUDE", "LONGITUDE", "ALTITUDE", "ECOREGION", "TYPEECO", "DRAINAGE_CLASS",
                        "SPECIES", "TREESTATUS", "TREEDHPCM", "TREEFREQ", "TREEHEIGHT", "ANNEE_SOND", "STANDTYPEECO", "STANDAGE")
  return(output)
}





###########################
# Spruce budworm defoliation
# Author Mathieu Fortin - June 2024
#
# SBW defoliation layers must be downloaded from DonneesQuebec
#
# 2014 à aujourd'hui (https://www.donneesquebec.ca/recherche/dataset/donnees-sur-les-perturbations-naturelles-insecte-tordeuse-des-bourgeons-de-lepinette/resource/3fc3801a-c29e-471e-ab25-7cd3c92997ed)
# last modification 2023-11-01
#
# 2007 à 2013 (https://www.donneesquebec.ca/recherche/dataset/donnees-sur-les-perturbations-naturelles-insecte-tordeuse-des-bourgeons-de-lepinette/resource/db7e4029-faa6-46dd-8bca-b1bcf386ec5e)
# last modification 2018-01-30
#
# 1992 à 2006 (https://www.donneesquebec.ca/recherche/dataset/donnees-sur-les-perturbations-naturelles-insecte-tordeuse-des-bourgeons-de-lepinette/resource/af8d3239-def7-4d72-9143-ae660630e850)
# last modification 2018-01-30
#
# 1967 à 1991 (https://www.donneesquebec.ca/recherche/dataset/donnees-sur-les-perturbations-naturelles-insecte-tordeuse-des-bourgeons-de-lepinette/resource/390e0b04-08fa-4fb3-93bb-16854f301dd8)
# last modification 2017-11-23
#
# Accessed on June 26th, 2024
#
###########################

rm(list = ls())
source("./compilation/utilityFunctions.R")

sf::sf_use_s2(T)

if (!require(sf)) {
  install.packages("sf")
  require(sf)
}

validateLayer <- function(filename) {
  message("Reading file ", filename)
  layer <- st_read(filename)
  message("Validating layer")
  layer <- sf::st_make_valid(layer)
  return(layer)
}

clipLayer <- function(polygonLayer) {
  years <- sort(unique(polygonLayer$ANNEE))
  output <- NULL
  for (y in years) {
    message("Clipping layer for year ", y)
    polygonYear <- polygonLayer[which(polygonLayer$ANNEE == y),]
    plotLayerWithSBW <- sf::st_intersection(plotLayer, polygonYear)
    output <- rbind(output, plotLayerWithSBW)
  }
  return(output)
}

hist1967_1991 <- validateLayer("./compilation/SBW/TBE_Historique_1967-1991/Historique_TBE_1967_1991.shp")
hist1992_2006 <- validateLayer("./compilation/SBW/TBE_Donnees_1992-2006/TBE_1992_2006.shp")
hist2007_2013 <- validateLayer("./compilation/SBW/TBE_Donnees_2007-2013/TBE_2007_2013.shp")
hist2014_auj <- validateLayer("./compilation/SBW/TBE_Donnees_2014-aujourdhui/TBE_2014_2023.shp")

output <- readRDSFile()
plotIndex <- output$plots
crs <- sf::st_crs(hist1992_2006)
plotLayer <- sf::st_as_sf(plotIndex, coords = c("longitudeDeg", "latitudeDeg"), dim = "XY", crs = crs)

sf_use_s2(F) # we don't use the s2 model

SBW1967_1991 <- clipLayer(hist1967_1991)
SBW1967_1991 <- SBW1967_1991[which(SBW1967_1991$NIVEAU != 0),]
SBW1967_1991[which(SBW1967_1991$NIVEAU %in% c(1,4,11)), "Niveau"] <- "Léger"
SBW1967_1991[which(SBW1967_1991$NIVEAU %in% c(2,5,6,12,13)), "Niveau"] <- "Modéré"
SBW1967_1991[which(SBW1967_1991$NIVEAU %in% c(3,7,14,15)), "Niveau"] <- "Grave"
table(SBW1967_1991$NIVEAU, SBW1967_1991$Niveau, useNA = "always")

SBW1992_2006 <- clipLayer(hist1992_2006)
unique(SBW1992_2006$Niveau)

SBW2007_2013 <- clipLayer(hist2007_2013)
SBW2007_2013$Niveau <- SBW2007_2013$NIVEAU
unique(SBW2007_2013$Niveau)

SBW2014_auj <- clipLayer(hist2014_auj)
SBW2014_auj <- SBW2014_auj[which(SBW2014_auj$Niveau != "Présence"),]
unique(SBW2014_auj$Niveau)

fieldsToKeep <- c("newID_PE", "ANNEE", "Niveau")
SBWTotal <- rbind(SBW1967_1991[,fieldsToKeep],
                  SBW1992_2006[,fieldsToKeep],
                  SBW2007_2013[,fieldsToKeep],
                  SBW2014_auj[,fieldsToKeep])

if (!require(reshape)) {
  install.packages("reshape")
  require(reshape)
}

SBWTotal$NiveauFactor <- factor(SBWTotal$Niveau, levels = c("Léger", "Modéré", "Grave"))
SBWTotal$NiveauFactorNum <- as.numeric(SBWTotal$NiveauFactor) ### 96467 obs
SBWTotalWithoutDuplicate <- aggregate(NiveauFactorNum ~ newID_PE + ANNEE, SBWTotal, FUN="max") ### 96441 obs
castedData <- cast(SBWTotalWithoutDuplicate, newID_PE ~ ANNEE)
castedData[is.na(castedData)] <- 0
fieldNames <- colnames(castedData)
fieldNames[2:length(fieldNames)] <- paste0("d",fieldNames[2:length(fieldNames)])
colnames(castedData) <- fieldNames
QcSBWDefoliation <- castedData

#QcSBWDefoliation <- readRDS("QcSBWDefoliation.Rds")
QcSBWDefoliation <- merge(output$plots[,c("ID_PE","newID_PE")], QcSBWDefoliation, by="newID_PE", all.x=T)
QcSBWDefoliation <- QcSBWDefoliation[,colnames(QcSBWDefoliation)[which(colnames(QcSBWDefoliation) != "ID_PE")]]
for (c in colnames(QcSBWDefoliation)) {
  if (any(is.na(QcSBWDefoliation[,c]))) {
    QcSBWDefoliation[which(is.na(QcSBWDefoliation[,c])),c] <- 0
  }
}

if ("sbwDefoliations" %in% names(output)) {
  compareTwoDataFrame(QcSBWDefoliation, output$sbwDefoliations)
}
output[["sbwDefoliations"]] <- QcSBWDefoliation
saveRDS(output, file = "./compilation/QcPSP.Rds", compress = "xz")





#############################################
# Script to retrieve the tree and plot data from DataBase version 2020-01-31
# Mathieu Fortin - July 2023
#   @output It produces ReadTrees.RData which
#               is a list that contains:
#               measurements,
#               sites,
#               photoInterpretedStands,
#               trees,
#               plots,
#               saplings
#############################################

rm(list=ls())
options(scipen=999)

source("./compilation/utilityFunctions.R")

if (!require("RODBC")) {
  install.packages("RODBC")
  require("RODBC")
}

.driverinfo <- "Driver={Microsoft Access Driver (*.mdb, *.accdb)};"
.db <- file.path("./compilation/PEP.mdb") # database path
if (!file.exists(.db)) {  ### unzip file if it does not exist yet
  stop("You must first extract the database from the PEP.7z file!")
}

.path <- paste0(.driverinfo, "DBQ=", .db)
channel <- odbcDriverConnect(.path, rows_at_time = 1)
message("Here are the tables in the database:")
sqlTables(channel, tableType = "TABLE")$TABLE_NAME

#### Read plot and measurement information ####

indexPlots <- sqlFetch(channel, "PLACETTE") #### 12 816 observations
indexPlots <- indexPlots[,!colnames(indexPlots) %in% c("OBJECTID", "SHAPE")]  # drop these two fields
indexMeasurements <- sqlFetch(channel, "PLACETTE_MES") ### 51 083 observations
indexMeasurements$year <- as.integer(format(as.Date(indexMeasurements$DATE_SOND, format="%Y-%m-%d"),"%Y"))
summary(indexMeasurements$year)
dataStation <- sqlFetch(channel, "STATION_PE") ### 51 083 obs
dataPhotoInterpretation <- sqlFetch(channel, "PEE_ORI_SOND") ### 51 083 obs
classification <- sqlFetch(channel,"CLASSI_ECO_PE") ### 12 816 obs
indexPlots <- merge(indexPlots, classification[,c("ID_PE", "REG_ECO")], by="ID_PE")

sol <- sqlFetch(channel, "STATION_SOL") # 32 465 obs
indexMeasurements <- merge(indexMeasurements, sol[,c("ID_PE_MES", "PH_HUMUS")], by="ID_PE_MES", all.x = T)

############# keep the last values ####################
setLastValueOf(dataStation, "TYPE_ECO", "EcoType", "ID_PE", "NO_MES")
setLastValueOf(dataStation, "ALTITUDE", "elevationM", "ID_PE", "NO_MES")
setLastValueOf(dataStation, "PC_PENT", "pentePerc", "ID_PE", "NO_MES")
setLastValueOf(dataStation, "CL_DRAI", "drainageCl", "ID_PE", "NO_MES")
setLastValueOf(dataStation, "CL_PENT", "penteCl", "ID_PE", "NO_MES")
setLastValueOf(dataStation, "DEP_SUR", "depot", "ID_PE", "NO_MES")
setLastValueOf(dataStation, "EXPOSITION", "exposition", "ID_PE", "NO_MES")
setLastValueOf(dataStation, "RELIEF", "relief", "ID_PE", "NO_MES")
setLastValueOf(indexMeasurements, "PH_HUMUS", "pH_humus", "ID_PE", "NO_MES")

fieldNames <- colnames(indexPlots)
fieldNames <- gsub("LATITUDE", "latitudeDeg", fieldNames)
fieldNames <- gsub("LONGITUDE", "longitudeDeg", fieldNames)
fieldNames <- gsub("REG_ECO", "regEco", fieldNames)
colnames(indexPlots) <- fieldNames

indexPlots[which(indexPlots$relief == "PLATEAU" & is.na(indexPlots$exposition)), "exposition"] <- 400
indexPlots[which(indexPlots$relief == "VALLÉE" & is.na(indexPlots$exposition)), "exposition"] <- 500

fieldsForHDRelationship <- c("latitudeDeg", "longitudeDeg", "elevationM", "EcoType", "regEco", "drainageCl")
indexPlots <- createDummyNonMissingValues(indexPlots, fieldsForHDRelationship)
indexPlots$vireeID <- floor(indexPlots$ID_PE * 0.01)
table(indexPlots$nonMissingValues)

removeAllExcept(c("indexMeasurements", "dataStation", "dataPhotoInterpretation", "indexPlots", "channel"))

#### Read tree information ####

dataTrees <- sqlFetch(channel, "DENDRO_ARBRES")  ### 2 089 643 obs
dataTrees$dbhCm <- dataTrees$DHP *.1
dataTrees <- merge(dataTrees, indexMeasurements[,c("ID_PE_MES", "year")], by="ID_PE_MES")
table(dataTrees[,"TIGE_HA"], useNA = "always")
table(dataTrees[which(dataTrees$year >= 2003),"TIGE_HA"], useNA = "always")

dataArbresEtudes <- sqlFetch(channel, "DENDRO_ARBRES_ETUDES") ### 420 211 obs
dataArbresEtudes <- dataArbresEtudes[which(dataArbresEtudes$ID_PE == floor(dataArbresEtudes$ID_ARBRE / 1000)),] # remove inconsistent ID_PE -- 406 664 obs
dataArbresEtudes <- dataArbresEtudes[which(dataArbresEtudes$NO_ARBRE == dataArbresEtudes$ID_ARBRE - dataArbresEtudes$ID_PE * 1000),] # remove inconsistent NO_ARBRE -- 402 762 obs
table(dataArbresEtudes$MET_SELEC)
#dataArbresEtudes <- dataArbresEtudes[which(dataArbresEtudes$MET_SELEC %in% c("L", , "S") & !is.na(dataArbresEtudes$HAUT_ARBRE)),] ### we keep only systematic sampling -- 226 844 obs left
### WE NOW KEEP ALL STUDY TREES THAT HAVE AT LEAST AN AGE OR A HEIGHT MEASUREMENT - MF20240109
dataArbresEtudes <- dataArbresEtudes[which(!is.na(dataArbresEtudes$HAUT_ARBRE) | !is.na(dataArbresEtudes$AGE)),] ### we keep all study trees with at least a height or an age measurement -- 338 840 obs left
dataArbresEtudes$hauteurM <- dataArbresEtudes$HAUT_ARBRE * .1
if (length(dataArbresEtudes[,1]) != length(aggregate(ID_ARBRE ~ ID_PE_MES + NO_ARBRE, dataArbresEtudes, FUN="length")[,1])) {
  stop("There are some duplicates in the dataset of study trees!")
}


dataTrees <- merge(dataTrees, dataArbresEtudes[,c("ID_PE_MES", "NO_ARBRE", "hauteurM", "NIVLECTAGE", "AGE", "SOURCE_AGE")],
                   by=c("ID_PE_MES",
                        "NO_ARBRE"), all.x = T)  ### still 2 089 643 obs
table(dataTrees$ETAT, useNA = "always")
dataStatus <- read.csv("./compilation/ReferenceTables/StatusTable.csv", fileEncoding = "UTF-16LE")
dataStatus$ETAT <- as.character(dataStatus$ETAT)
dataTrees <- merge(dataTrees, dataStatus[,c("ETAT","STATUT")], by=c("ETAT"), all.x = T) ### still 2 089 643 obs

dataSapling <- sqlFetch(channel, "DENDRO_GAULES")  ### 223 500 obs

close(channel)

removeAllExcept(c("indexMeasurements", "dataStation", "dataPhotoInterpretation", "indexPlots", "dataTrees", "dataSapling"))

###### Check if there are any changes #######

readTreeFilename <- "./compilation/ReadTrees.RData"

if (file.exists(readTreeFilename)) {
  load(file=readTreeFilename)

  message("Comparing plot index")
  print(compareTwoDataFrame(indexPlots, inventory$plots))
  message("Comparing measurement index")
  print(compareTwoDataFrame(indexMeasurements, inventory$measurements))
  message("Comparing station data")
  print(compareTwoDataFrame(dataStation, inventory$sites))
  message("Comparing photo-interpreted data")
  print(compareTwoDataFrame(dataPhotoInterpretation, inventory$photoInterpretedStands))
  message("Comparing tree data")
  print(compareTwoDataFrame(dataTrees, inventory$trees))
  message("Comparing sapling data")
  print(compareTwoDataFrame(dataSapling, inventory$saplings))
} else {
  message(paste(readTreeFilename, "does not exist yet!"))
}

inventory <- list()
inventory$measurements <- indexMeasurements
inventory$sites <- dataStation
inventory$photoInterpretedStands <- dataPhotoInterpretation
inventory$trees <- dataTrees
inventory$plots <- indexPlots
inventory$saplings <- dataSapling

save(inventory, file=readTreeFilename, compress = "xz")


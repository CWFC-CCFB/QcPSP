###########################################
# Formatting the database to make it 
# available for different projects. 
# This script sends the data to Java and retrieves the 
# corrected data.
# Mathieu Fortin - July 2023
#   @output plotIndex.RData
#   @output measurementIndex.RData
#   @output treeIndex.RData
#   @output correctedTreeMeasurements.RData
###########################################

rm(list = ls())
source("utilityFunctions.R")

##### Correcting measurement table for relocated plots #####

load(file = "ReadTrees.RData")

measurements <- inventory$measurements  ## 51 083 obs
sites <- inventory$sites
measurements <- merge(measurements, sites[,c("ID_PE_MES", "ORIGINE", "PERTURB")], by="ID_PE_MES")

table(measurements$STATUT_MES, useNA="always")
measurements <- measurements[is.na(measurements$STATUT_MES) | measurements$STATUT_MES %in% c("RE", "RL"),] ## 50 430 obs left.

measurements.tmp <- measurements[, c("ID_PE_MES", "ID_PE", "year", "STATUT_MES")]
plotIndex <- unique(measurements$ID_PE)
output <- NULL
for (i in 1:length(plotIndex)) {
  if (i%%1000 == 0) {
    message(paste("Processing plot", i, "/", length(plotIndex)))
  }
  measurements.i <- measurements.tmp[which(measurements.tmp$ID_PE == plotIndex[i]),]
  measurements.i <- measurements.i[order(measurements.i$year),]
  relocated <- F
  for (k in 1:length(measurements.i[,1])) {
    if (measurements.i[k,"STATUT_MES"] %in% c("RL")) {    ## we assume RE (restablised plots are ok)
      relocated <- T
    }    
    if (relocated) {
      measurements.i[k,"newID_PE"] <- measurements.i[k,"ID_PE"] + 50
    } else {
      measurements.i[k,"newID_PE"] <- measurements.i[k,"ID_PE"]
    }
  }
  output <- rbind(output, measurements.i)
}

measurements <- merge(output[,-2], measurements, by = c("year", "STATUT_MES", "ID_PE_MES"))
removeAllExcept(c("inventory", "measurements"))
length(which(measurements$newID_PE != measurements$ID_PE)) ### 699 new plot ID
message(paste("Number of relocated plots",length(which(measurements$newID_PE != measurements$ID_PE))))
message(paste("Number of plots before considering relocation", length(unique(measurements$ID_PE))))  ## should be 12 816 plots
message(paste("Number of plots after considering relocation", length(unique(measurements$newID_PE))))  ## should be 12 816 plots

removeAllExcept(c("inventory", "measurements"))


##### Correcting plot and measurement index tables #####

measurementIndex <- measurements[,c("ID_PE_MES", "ID_PE", "newID_PE", "year", "NO_MES", "ORIGINE", "PERTURB", "DATE_SOND")]  
measurementIndex <- measurementIndex[order(measurementIndex$newID_PE, measurementIndex$year),]
measurementIndex$k <- 1:length(measurementIndex[,1]) ### 50 430 plot measurements

output <- NULL
i <- 0
for (newID_PE in unique(measurementIndex$newID_PE)) {
  i <- i + 1
  if (i%%1000 == 0) {
    message(paste("Processing measurement", i, length(unique(measurementIndex$newID_PE))))
  }
  measurementIndex.i <- measurementIndex[which(measurementIndex$newID_PE == newID_PE),]
  measurementIndex.i$newNO_MES <- 1:length(measurementIndex.i[,1])
  output <- rbind(output, measurementIndex.i)
}

message(paste("Number of renumbered measurements id", length(which(output$NO_MES != output$newNO_MES))))

measurementIndex <- output
removeAllExcept(c("inventory", "measurementIndex", "measurements"))

plotIndexNbMes <- aggregate(year ~ newID_PE + ID_PE, measurementIndex, FUN="length")
plotIndexMinYear <- aggregate(year ~ newID_PE + ID_PE, measurementIndex, FUN="min")
plotIndexMaxYear <- aggregate(year ~ newID_PE + ID_PE, measurementIndex, FUN="max")
plotIndex <- merge(plotIndexNbMes, plotIndexMinYear, by = c("newID_PE", "ID_PE"))
plotIndex <- merge(plotIndex, plotIndexMaxYear, by = c("newID_PE", "ID_PE"))
removeAllExcept(c("inventory", "measurementIndex", "measurements", "plotIndex"))
colnames(plotIndex) <- c("newID_PE", "ID_PE", "nbMeasurementsAfterFiltering", "minYearAfterFiltering", "maxYearAfterFiltering")
plotIndex <- merge(plotIndex, inventory$plots, by=c("ID_PE"))
plotIndex <- plotIndex[order(plotIndex$newID_PE),] ### 12 816 plots

table(plotIndex$regEco, useNA = "always")


QcPlotIndex <- plotIndex[,c("ID_PE", "newID_PE", "nbMeasurementsAfterFiltering",
                            "minYearAfterFiltering", "maxYearAfterFiltering",
                            "latitudeDeg", "longitudeDeg", "elevationM",
                            "regEco", "EcoType", "pentePerc", "drainageCl",
                            "penteCl", "depot", "exposition", "pH_humus",
                            "nonMissingValues")]

message("Saving plot index...")
output <- readRDSFile()
output[["plots"]] <- QcPlotIndex  ### Input no 1
saveRDS(output, file = "QcPSP.Rds", compress = "xz")
message("Done.")

removeAllExcept(c("inventory", "measurementIndex", "measurements", "QcPlotIndex"))

#### Exporting tree table for Java pattern processing #### 

invalidMeasurements <- inventory$measurements

invalidMeasurements <- invalidMeasurements[!is.na(invalidMeasurements$STATUT_MES) & !invalidMeasurements$STATUT_MES %in% c("", "RE", "RL"),] ## 653 measurements are invalid

trees <- inventory$trees ## 2 089 643 obs
trees <- removeTheseFields(trees, "year")
treesInInvalidMeasurements <- merge(trees, invalidMeasurements[,c("ID_PE_MES", "STATUT_MES")], by = "ID_PE_MES")  ### 363 trees in invalid measurements
trees <- merge(measurementIndex[,c("ID_PE_MES", "newID_PE", "ID_PE", "k", "year")], trees, by=c("ID_PE_MES","ID_PE"))  ## 2 089 280 obs left
trees <- trees[,c("newID_PE", "NO_ARBRE", "k", "year", "ESSENCE", "ETAT", "IN_1410", "dbhCm", "hauteurM", "NIVLECTAGE", "AGE", "SOURCE_AGE")]
trees <- trees[order(trees$newID_PE, trees$NO_ARBRE, trees$year),]

nbMeasurementsByTrees <- aggregate(dbhCm ~ newID_PE + NO_ARBRE, trees, FUN="length")
message("Number of trees with x measurements")
table(nbMeasurementsByTrees$dbhCm) ## nb measurements per tree

### Processing in Java  
options(digits = 15) ## to avoid scientific notation
write.csv(trees, file = file.path(getwd(), "treesBeforeCorrection.csv"), row.names = F)  

#### Pattern correction in Java ####

if (!require(J4R)) {
  install.packages("https://sourceforge.net/projects/repiceasource/files/latest/download", repos = NULL,  type="source")
  require(J4R)
}
if (packageVersion("J4R") < "1.2.1") {
  message(paste("Current version of J4R is", packageVersion("J4R")))
  message(paste("Version >= 1.2.1 is needed. The latest version will be downloaded from SourceForge!"))
  detach("package:J4R", unload=TRUE)
  install.packages("https://sourceforge.net/projects/repiceasource/files/latest/download", repos = NULL,  type="source")
  require(J4R)
}
classPath <- c(file.path(getwd(),"JavaProcessing/bin/"), paste(getwd(), "JavaProcessing/ext/*", sep="/"));
connectToJava(extensionPath = classPath, memorySize = 3000)
#getClassLoaderPaths()

treeBeforeCorrectionFilename <- file.path(getwd(),"treesBeforeCorrection.csv")
message("Importing data in Java...")
formatter <- createJavaObject("processing.QuebecPEPFormatting", treeBeforeCorrectionFilename)
formatter$setFieldnamesForSplitting(as.JavaArray(c("newID_PE", "NO_ARBRE")))
formatter$setFieldnamesForSorting(as.JavaArray("year"))
dsgm <- formatter$splitAndSort()

message("Performing automated status correction (first round)...")
cat(formatter$performStatusCorrection(dsgm, T))
message("Performing manual status correction")
formatter$performManualStatusCorrections(dsgm)
dsgm <- formatter$splitAndSort() # we redefine the DataSetGroupMap instance after running the automatic and manuel corrections
message("Performing automated status correction (second round)...")
cat(formatter$performStatusCorrection(dsgm, T))

dsgm <- formatter$splitAndSort()
message("Performing automated species correction (first round)")
cat(formatter$performSpeciesCorrection(dsgm, T))

dsgm <- formatter$splitAndSort()
message("Performing automated in1410 correction (first round)")
cat(formatter$performIn1410Correction(dsgm, T))
message("Performing manual in1410 correction")
formatter$performManualIn1410Corrections(dsgm)
dsgm <- formatter$splitAndSort()
message("Performing automated in1410 correction (second round)...")
cat(formatter$performStatusCorrection(dsgm, T))

exportCorrectedFilename <- file.path(getwd(),"treesCorrected.csv")
dsgm$save(exportCorrectedFilename);
shutdownClient()


#### Creating tree index table after Java processing ####
correctedTreeMeasurements <- read.csv(file = "treesCorrected.csv", sep=";", dec=".")  ### 2 089 280 obs

correctedTreeMeasurements <- correctedTreeMeasurements[order(correctedTreeMeasurements$newID_PE, correctedTreeMeasurements$NO_ARBRE, correctedTreeMeasurements$year),]

##### Additional manual corrections #####

correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 9909901801 &
                                  correctedTreeMeasurements$NO_ARBRE == 2 &
                                  correctedTreeMeasurements$year == 2004), "ETAT"] <- "40" ### Missing replaced by 40
correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 9909901801 &
                                  correctedTreeMeasurements$NO_ARBRE == 2 &
                                  correctedTreeMeasurements$year == 2009), "ETAT"] <- "10" ### 40 replaced by 10

correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 9909903301 &
                                  correctedTreeMeasurements$NO_ARBRE == 1 & 
                                  correctedTreeMeasurements$year == 2004), "ETAT"] <- "40"  ### Missing replaced by 40
correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 9909903301 &
                                  correctedTreeMeasurements$NO_ARBRE == 1 & 
                                  correctedTreeMeasurements$year == 2009), "ETAT"] <- "10"  ### 40 replaced by 10


table(correctedTreeMeasurements$ETAT, useNA = "always")
missingStatus <- correctedTreeMeasurements[which(is.na(correctedTreeMeasurements$ETAT)),]
missingStatusButMerchantableDbh <- missingStatus[which(missingStatus$dbhCm > 9), c("newID_PE", "NO_ARBRE", "year")]
if (length(missingStatusButMerchantableDbh[,1]) > 0) {
  stop("Some trees are merchantable but they do not have any status")
}

indexTree0nbMes <- aggregate(year ~ newID_PE + NO_ARBRE, correctedTreeMeasurements, FUN="length")
indexTree0minYear <- aggregate(year ~ newID_PE + NO_ARBRE, correctedTreeMeasurements, FUN="min")
indexTree0maxYear <- aggregate(year ~ newID_PE + NO_ARBRE, correctedTreeMeasurements, FUN="max")
indexTree0 <- merge(indexTree0nbMes, indexTree0minYear, by = c("newID_PE", "NO_ARBRE"))
indexTree0 <- merge(indexTree0, indexTree0maxYear, by = c("newID_PE", "NO_ARBRE"))
colnames(indexTree0) <- c("newID_PE", "NO_ARBRE", "nbMeasurements", "minYear", "maxYear")
indexTree1 <- aggregate(year ~ newID_PE + NO_ARBRE + ESSENCE, correctedTreeMeasurements, FUN="length")
treeIndex <- merge(indexTree0, indexTree1, by=c("newID_PE", "NO_ARBRE"), all.x=T)
treeIndex <- treeIndex[order(treeIndex$newID_PE, treeIndex$NO_ARBRE), c("newID_PE", "NO_ARBRE", "ESSENCE", "nbMeasurements", "minYear", "maxYear")]
treeIndex$j <- 1:length(treeIndex[,1]) ### 814 232 trees 
table(is.na(treeIndex$ESSENCE)) ### there are 6561 trees with NA species
removeAllExcept(c("inventory", "in1410", "measurementIndex", "measurements", "QcPlotIndex", "treeIndex", "correctedTreeMeasurements"))


in1410 <- aggregate(year ~ newID_PE + NO_ARBRE + IN_1410, 
                    correctedTreeMeasurements[which(correctedTreeMeasurements$year >= 2003 & correctedTreeMeasurements$IN_1410 != ""),], 
                    FUN="min") ### 27 631 tree measurements with variable IN_1410 != "" since 2003, 74 have been corrected above
duplicated_in1410 <- aggregate(IN_1410 ~ newID_PE + NO_ARBRE, in1410, FUN="length")
duplicated_in1410 <- duplicated_in1410[which(duplicated_in1410$IN_1410 > 1),]
if (length(duplicated_in1410[,1]) > 0) { ## should be 0
  stop("There are duplicated values for the IN_1410 field")
}  

treeIndex <- merge(treeIndex, in1410[,c("newID_PE","NO_ARBRE","IN_1410")], by=c("newID_PE","NO_ARBRE"), all.x = T) ### still 814 232 trees
treeIndex[which(is.na(treeIndex$IN_1410)), "IN_1410"] <- "N"

correctedTreeMeasurements <- merge(treeIndex[,c("newID_PE","NO_ARBRE","j","ESSENCE", "IN_1410")], 
                                   correctedTreeMeasurements[,c("newID_PE", "NO_ARBRE", "k", "year", "ETAT", "dbhCm", "hauteurM", "NIVLECTAGE", "AGE", "SOURCE_AGE")], 
                                   by=c("newID_PE", "NO_ARBRE")) ###  2 089 280 tree measurements

#table(correctedTreeMeasurements$IN_1410, correctedTreeMeasurements$year)
removeAllExcept(c("inventory", "measurementIndex", "measurements", "QcPlotIndex", "treeIndex", "correctedTrees", "correctedTreeMeasurements"))


intruders <- aggregate(ETAT ~ newID_PE + j, correctedTreeMeasurements[which(correctedTreeMeasurements$ETAT == "25"), c("newID_PE","j","ETAT")], FUN="length")
intruders$intruder <- T
  
treeIndex <- merge(treeIndex, intruders[,c("newID_PE","j","intruder")], by=c("newID_PE","j"), all.x=T) ### still 814 232 trees
treeIndex[which(is.na(treeIndex$intruder)),"intruder"] <- F
table(treeIndex$intruder) ## 4381 intruders

correctedTreeMeasurements <- merge(treeIndex[,c("newID_PE","NO_ARBRE","j","ESSENCE", "IN_1410", "intruder")], 
                                   correctedTreeMeasurements[,c("newID_PE", "NO_ARBRE", "k", "year", "ETAT", "dbhCm", "hauteurM", "NIVLECTAGE", "AGE", "SOURCE_AGE")], 
                                   by=c("newID_PE", "NO_ARBRE")) ###  2 089 280 tree measurements

correctedTreeMeasurements <- merge(measurementIndex[,c("newID_PE","k","newNO_MES")],
                                   correctedTreeMeasurements, 
                                   by=c("newID_PE","k"))  ### 2 089 280 tree measurements
removeAllExcept(c("inventory", "measurementIndex", "measurements", "QcPlotIndex", "treeIndex", "correctedTreeMeasurements"))

# ### Correcting weird sapling statuses
# correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 9003104202 & 
#                                   correctedTreeMeasurements$NO_ARBRE == 24 & 
#                                   correctedTreeMeasurements$year == 1990), "dbhCm"] <- 10.6   ## dbh measurement error here assumed to be 10.6 given the other measurements
# correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 9209500601 & 
#                                   correctedTreeMeasurements$NO_ARBRE == 15 &
#                                   correctedTreeMeasurements$year == 1992), "ETAT"] <- "GV" ## sapling measured as commercial tree
# correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 9909901601 & 
#                                   correctedTreeMeasurements$NO_ARBRE == 105 & 
#                                   correctedTreeMeasurements$year == 2004), "ETAT"] <- "GV" ## sapling measured as commercial tree
# saplingsWithWeirdStatuses <- correctedTreeMeasurements[which(correctedTreeMeasurements$dbhCm < 9.1 & 
#                                   !correctedTreeMeasurements$ETAT %in% c("15", "24", "25", "26", "", "GM", "GV", "GA") ),]
# #sample <- correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 9909901601 & correctedTreeMeasurements$NO_ARBRE == 105), ]
# if (length(saplingsWithWeirdStatuses[,1]) > 0) {
#   stop("Some saplings have inconsistent statuses!")
# }

seeminglyNotMeasured <- which(is.na(correctedTreeMeasurements$ESSENCE) & is.na(correctedTreeMeasurements$ETAT) & is.na(correctedTreeMeasurements$dbhCm))
if (length(seeminglyNotMeasured) > 0) {
  stop("Some records seem to be empty!")
}


#### Living trees with missing diameters ####
aliveStatuses <- c("10", "12", "30", "32", "40", "42", "50", "52")

## correcting for missing measurement for tree 7409703602 - 49 (Interpolation)
dbh1974 <- correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 7409703602 & 
                                             correctedTreeMeasurements$NO_ARBRE == 49 & 
                                             correctedTreeMeasurements$year == 1974), "dbhCm"]
dbh1992 <- correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 7409703602 & 
                                             correctedTreeMeasurements$NO_ARBRE == 49 & 
                                             correctedTreeMeasurements$year == 1992), "dbhCm"]
correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 7409703602 & 
                                  correctedTreeMeasurements$NO_ARBRE == 49 & 
                                  correctedTreeMeasurements$year == 1980), "dbhCm"] <- dbh1974 + (dbh1992 - dbh1974)/18 * 6

## correcting for missing measurement for tree 7409703602 - 5 (Interpolation)
dbh1974 <- correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 7409703602 & 
                                             correctedTreeMeasurements$NO_ARBRE == 5 & 
                                             correctedTreeMeasurements$year == 1974), "dbhCm"]
dbh1992 <- correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 7409703602 & 
                                             correctedTreeMeasurements$NO_ARBRE == 5 & 
                                             correctedTreeMeasurements$year == 1992), "dbhCm"]
correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 7409703602 & 
                                  correctedTreeMeasurements$NO_ARBRE == 5 & 
                                  correctedTreeMeasurements$year == 1980), "dbhCm"] <- dbh1974 + (dbh1992 - dbh1974)/18 * 6

## correcting for missing measurement for tree 7501701601 - 32 (Interpolation) 
dbh1981 <- correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 7501701601 & 
                                             correctedTreeMeasurements$NO_ARBRE == 32 & 
                                             correctedTreeMeasurements$year == 1981), "dbhCm"]
dbh2005 <- correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 7501701601 & 
                                             correctedTreeMeasurements$NO_ARBRE == 32 & 
                                             correctedTreeMeasurements$year == 2005), "dbhCm"]
correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 7501701601 & 
                                  correctedTreeMeasurements$NO_ARBRE == 32 & 
                                  correctedTreeMeasurements$year == 1996), "dbhCm"] <- dbh1981 + (dbh2005 - dbh1981)/24 * 15


treesWithMissingDBH <- correctedTreeMeasurements[which(correctedTreeMeasurements$ETAT %in% aliveStatuses &
                                                   correctedTreeMeasurements$intruder == F & 
                                                   is.na(correctedTreeMeasurements$dbhCm)),] 
#sample <- correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 9003104202 & correctedTreeMeasurements$NO_ARBRE == 3), ]
message(paste("There are", length(treesWithMissingDBH[,1]),"records with missing diameters!")) ### still 4 trees with missing dbh

#### Correcting inconsistent dbh ####

                                  
correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 7000400702 & 
                                  correctedTreeMeasurements$NO_ARBRE == 5 & 
                                  correctedTreeMeasurements$year == 1997), "dbhCm"] <- 20.2 # instead of 50.2 
correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 7000413402 & 
                                  correctedTreeMeasurements$NO_ARBRE == 17 & 
                                  correctedTreeMeasurements$year == 1970), "dbhCm"] <- 44.7 # instead of 14.7
correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 7309600201 & 
                                  correctedTreeMeasurements$NO_ARBRE == 8 & 
                                  correctedTreeMeasurements$year == 1980), "dbhCm"] <- 28.5 # instead of 52.7
correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 8809400502 & 
                                  correctedTreeMeasurements$NO_ARBRE == 13 & 
                                  correctedTreeMeasurements$year == 1988), "dbhCm"] <- 24.1 # instead of 14.1
correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 7100810602 & 
                                  correctedTreeMeasurements$NO_ARBRE == 8 & 
                                  correctedTreeMeasurements$year == 1971), "dbhCm"] <- 24.4 # instead of 42.4
correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 7209602102 & 
                                  correctedTreeMeasurements$NO_ARBRE == 17 & 
                                  correctedTreeMeasurements$year == 1972), "dbhCm"] <- 9.2 # instead of 29.2
correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 7109603901 & 
                                  correctedTreeMeasurements$NO_ARBRE == 12 & 
                                  correctedTreeMeasurements$year == 1978), "dbhCm"] <- 43.7 # instead of 33.7
correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 7303500301 & 
                                  correctedTreeMeasurements$NO_ARBRE == 13 & 
                                  correctedTreeMeasurements$year == 1997), "dbhCm"] <- 27.5 # instead of 97.5
correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 7608608902 & 
                                  correctedTreeMeasurements$NO_ARBRE == 28 & 
                                  correctedTreeMeasurements$year == 1989), "dbhCm"] <- 42.3 # instead of 32.3
correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 9109613801 & 
                                  correctedTreeMeasurements$NO_ARBRE == 29 & 
                                  correctedTreeMeasurements$year == 1997), "dbhCm"] <- 12.5 # instead of 22.5
correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 7608801801 & 
                                  correctedTreeMeasurements$NO_ARBRE == 9 & 
                                  correctedTreeMeasurements$year == 1989), "dbhCm"] <- 18.3 # instead of 10.3
correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 7100803601 & 
                                  correctedTreeMeasurements$NO_ARBRE == 1 & 
                                  correctedTreeMeasurements$year == 1971), "dbhCm"] <- 9.5 # instead of 39.5
correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 7601902902 & 
                                  correctedTreeMeasurements$NO_ARBRE == 13 & 
                                  correctedTreeMeasurements$year == 1988), "dbhCm"] <- 39.8 # instead of 45.3
correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 7109601001 & 
                                  correctedTreeMeasurements$NO_ARBRE == 6 & 
                                  correctedTreeMeasurements$year == 1978), "dbhCm"] <- 33.5 # instead of 23.5
correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 7501701202 & 
                                  correctedTreeMeasurements$NO_ARBRE == 5 & 
                                  correctedTreeMeasurements$year == 2005), "dbhCm"] <- 19.1 # instead of 9.1
correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 9609903102 & 
                                  correctedTreeMeasurements$NO_ARBRE == 35 & 
                                  correctedTreeMeasurements$year == 1996), "dbhCm"] <- 11.0 # instead of 21.0
correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 7100813101 & 
                                  correctedTreeMeasurements$NO_ARBRE == 19 & 
                                  correctedTreeMeasurements$year == 1978), "dbhCm"] <- 35.5 # instead of 25.5
correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 7608900402 & 
                                  correctedTreeMeasurements$NO_ARBRE == 5 & 
                                  correctedTreeMeasurements$year == 1984), "dbhCm"] <- 23.7 # instead of 33.7
correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 9809901501 & 
                                  correctedTreeMeasurements$NO_ARBRE == 50 & 
                                  correctedTreeMeasurements$year == 2003), "dbhCm"] <- 12.1 # instead of 22.1
correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 7209300102 & 
                                  correctedTreeMeasurements$NO_ARBRE == 20 & 
                                  correctedTreeMeasurements$year == 1979), "dbhCm"] <- 41.5 # instead of 11.5
correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 7601600801 & 
                                  correctedTreeMeasurements$NO_ARBRE == 13 & 
                                  correctedTreeMeasurements$year == 1989), "dbhCm"] <- 40.1 # instead of 30.1
correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 7208802402 & 
                                  correctedTreeMeasurements$NO_ARBRE == 26 & 
                                  correctedTreeMeasurements$year == 1996), "dbhCm"] <- 29.2 # instead of 39.2
correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 7501409201 & 
                                  correctedTreeMeasurements$NO_ARBRE == 29 & 
                                  correctedTreeMeasurements$year == 1990), "dbhCm"] <- 9.6 # instead of 19.6
correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 7501106402 & 
                                  correctedTreeMeasurements$NO_ARBRE == 16 & 
                                  correctedTreeMeasurements$year == 1997), "dbhCm"] <- 26.2 # instead of 36.2
correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 9109612201 & 
                                  correctedTreeMeasurements$NO_ARBRE == 68 & 
                                  correctedTreeMeasurements$year == 2012), "dbhCm"] <- 12.6 # instead of 18.6
correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 9109606801 & 
                                  correctedTreeMeasurements$NO_ARBRE == 52 & 
                                  correctedTreeMeasurements$year == 1997), "dbhCm"] <- 35.4 # instead of 25.4
correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 7609503801 & 
                                  correctedTreeMeasurements$NO_ARBRE == 2 & 
                                  correctedTreeMeasurements$year == 1997), "dbhCm"] <- 23.9 # instead of 33.9
correctedTreeMeasurements[which(correctedTreeMeasurements$newID_PE == 7209000901 & 
                                  correctedTreeMeasurements$NO_ARBRE == 53 & 
                                  correctedTreeMeasurements$year == 1989), "dbhCm"] <- 17.6 # instead of 27.6

#### Saving files ####

message("Saving tree index...")
output <- readRDSFile()
# QcTreeIndexOLD <- readRDS(file = "QcTreeIndex.Rds")  ### TODO replace by output$treeIndex
# print(compareTwoDataFrame(QcTreeIndexOLD, treeIndex))
output[["treeIndex"]] <- treeIndex  ### Input no 2
saveRDS(output, file = "QcPSP.Rds", compress = "xz")
message("Done.")

correctedTreeMeasurements <- correctedTreeMeasurements[order(correctedTreeMeasurements$newID_PE, 
                                                             correctedTreeMeasurements$NO_ARBRE,
                                                             correctedTreeMeasurements$k),] 

QcTreeMeasurements <- correctedTreeMeasurements
correctedTreeMeasurementIntermediatefilename <- file.path(getwd(), "correctedTreeMeasurementsIntermediate.RData")

save(QcTreeMeasurements, file = correctedTreeMeasurementIntermediatefilename)  
save(measurementIndex, file = "measurementIndexIntermediate.RData")

############### Summarizing basal areas and stem density per measurements in the whole plot (400 m2 and 625 m2 subplots) ###########

rm(list=ls())
source("utilityFunctions.R")
load(file = "correctedTreeMeasurementsIntermediate.RData")
load(file = "measurementIndexIntermediate.RData")

table(QcTreeMeasurements$ESSENCE)
table(QcTreeMeasurements$ETAT)

aliveStatuses <- c("10", "12", "30", "32", "40", "42", "50", "52")

dataToProcess <- QcTreeMeasurements[which(QcTreeMeasurements$intruder == F),] ### 2 089 280 down to 2 079 179 obs.
dataToProcess <- dataToProcess[which(dataToProcess$ETAT %in% aliveStatuses),] ### 2 079 179 down to 1 577 874 obs.
dataToProcess <- dataToProcess[which(dataToProcess$dbhCm >= 9.1),] ### 1 577 874 down to 1 577 868 obs.
table(dataToProcess$ESSENCE, useNA = "always")
dataToProcess$n <- 25
dataToProcess[which(dataToProcess$year >= 2003 & dataToProcess$dbhCm >= 31.0), "n"] <- 16
table(dataToProcess$n, useNA = "always")
dataToProcess$g <- dataToProcess$dbhCm^2 * pi * 2.5e-5 * dataToProcess$n

##### BAL calculation #####
dataToProcess <- dataToProcess[order(dataToProcess$k, -dataToProcess$dbhCm),]
dataToProcess$BAL <- 0

refK <- -1
for (i in 1:nrow(dataToProcess)) {
  if (i%%10000 == 0) {
    message(paste("Processing observation", i))
  }
  if (dataToProcess[i, "k"] != refK) {
    refK <- dataToProcess[i, "k"]
    sumBA <- dataToProcess[i, "g"]
    dataToProcess[i,"BAL"] <- 0
  } else {
    dataToProcess[i,"BAL"] <- sumBA
    sumBA <- sumBA + dataToProcess[i, "g"]
  }
}

QcTreeMeasurements <- merge(QcTreeMeasurements, dataToProcess[,c("k", "j", "BAL")], by=c("k", "j"), all.x=T)
QcTreeMeasurements <- QcTreeMeasurements[,c("j","k", "ETAT", "dbhCm", "hauteurM", "BAL", "NIVLECTAGE", "AGE", "SOURCE_AGE")] 

output <- readRDSFile()
output[["treeMeasurements"]] <- QcTreeMeasurements ### Input no 3
saveRDS(output, file = "QcPSP.Rds", compress = "xz")


basalAreasPerSpecies <- aggregate(g ~ k + ESSENCE, dataToProcess, FUN="sum")
library(reshape)
basalAreasPerSpecies <- cast(basalAreasPerSpecies, k ~ ESSENCE, FUN="sum")
fieldNames <- colnames(basalAreasPerSpecies)
fieldNames[2:length(fieldNames)] <- paste("G_", fieldNames[2:length(fieldNames)], sep="") 
colnames(basalAreasPerSpecies) <- fieldNames

basalAreas <- aggregate(g ~ k, dataToProcess, FUN="sum")
fieldNames <- colnames(basalAreas)
fieldNames[2] <- "G_TOT" 
colnames(basalAreas) <- fieldNames

basalAreas <- merge(basalAreas, basalAreasPerSpecies, by="k")

stemDensitiesPerSpecies <- aggregate(n ~ k + ESSENCE, dataToProcess, FUN="sum")
stemDensitiesPerSpecies <- cast(stemDensitiesPerSpecies, k ~ ESSENCE, FUN="sum")
fieldNames <- colnames(stemDensitiesPerSpecies)
fieldNames[2:length(fieldNames)] <- paste("N_", fieldNames[2:length(fieldNames)], sep="") 
colnames(stemDensitiesPerSpecies) <- fieldNames

stemDensities <- aggregate(n ~ k, dataToProcess, FUN="sum")
fieldNames <- colnames(stemDensities)
fieldNames[2] <- "N_TOT" 
colnames(stemDensities) <- fieldNames

stemDensities <- merge(stemDensities, stemDensitiesPerSpecies, by="k")
basalAreasStemDensities <- merge(stemDensities, basalAreas, by="k")

measurementIndicesTmp <- merge(measurementIndex[,c("newID_PE","k")], basalAreasStemDensities, by="k", all.x = T) ### 50 430 obs
for (j in 3:length(measurementIndicesTmp[1,])) {
  measurementIndicesTmp[which(is.na(measurementIndicesTmp[,j])),j] <- 0  
}

measurementIndex <- merge(measurementIndex, measurementIndicesTmp, by=c("newID_PE","k"))  ### 50 430 obs
measurementIndex <- measurementIndex[order(measurementIndex$newID_PE, measurementIndex$k),]

QcMeasurementIndex <- measurementIndex

output <- readRDSFile()
output[["plotMeasurements"]] <- QcMeasurementIndex ### Input no 4
saveRDS(output, file = "QcPSP.Rds", compress = "xz")

#### Creating saplings table ####

rm(list = ls())
source("utilityFunctions.R")

load(file = "ReadTrees.RData")
output <- readRDSFile()

saplings <- inventory$saplings

saplings <- merge(saplings, output$plotMeasurements[,c("ID_PE", "NO_MES", "k")], by=c("ID_PE", "NO_MES")) ### 25 records are dropped because of missing measurement in the QcMeasurementIndex table see ISSUE ON GITHUB MF20240122
QcSaplingMeasurements <- saplings[,c("k", "ESSENCE", "CL_DHP", "NB_TIGE")]
output[["saplings"]] <- QcSaplingMeasurements ### input no 5
saveRDS(output, file = "QcPSP.Rds", compress = "xz")


#### Creating photoInterpretedStands table ####

rm(list = ls())
source("utilityFunctions.R")

load(file = "ReadTrees.RData")
output <- readRDSFile()
output[["photoInterpretedStands"]] <- inventory$photoInterpretedStands ### input no 6
saveRDS(output, file = "QcPSP.Rds", compress = "xz")




#### Comparing new structure to previous ones ####

# rm(list = ls())
# source("utilityFunctions.R")
# 
# output <- readRDSFile()
# 
# compareTwoDataFrame(readRDS("QcPlotIndex.Rds"), output$plots)
# compareTwoDataFrame(readRDS("QcMeasurementIndex.Rds"), output$plotMeasurements)
# compareTwoDataFrame(readRDS("QcTreeIndex.Rds"), output$treeIndex)
# compareTwoDataFrame(readRDS("QcTreeMeasurements.Rds"), output$treeMeasurements)
# compareTwoDataFrame(readRDS("QcSaplingMeasurements.Rds"), output$saplings)



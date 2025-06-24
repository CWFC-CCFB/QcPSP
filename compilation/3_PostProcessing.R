#'
#' Final formatting
#' Converting doubles to integers
#'
#' @author Mathieu Fortin
#'

#### Change numeric for integers ####

rm(list = ls())
source("./compilation/utilityFunctions.R")
require(bit64)
output <- readRDSFile()
newOutput <- list()
integerFields <- c("ID_PE", "newID_PE", "ID_PE_MES")
for (n in names(output)) {
  message("Processing ", n)
  df <- output[[n]]
  for (f in integerFields) {
    if (f %in% colnames(df)) {
      message("    Processing field ", f)
      if (any(abs(df[,f]) > 2147483647)) {
        if (!"integer64" %in% class(df[,f])) {
          df[,f] <- as.integer64(as.character(df[,f]))
        }
      } else {
        if (!"integer" %in% class(df[,f])) {
          df[,f] <- as.integer(df[,f])
        }
      }
    }
  }
  newOutput[[n]] <- df
}
saveRDS(newOutput, file = "./compilation/QcPSP.Rds", compress = "xz")



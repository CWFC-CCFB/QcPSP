#'
#' Final formatting
#' Converting doubles to integers
#'
#' @author Mathieu Fortin
#'

#### Change numeric for integers ####

rm(list = ls())
source("./compilation/utilityFunctions.R")
#require(bit64)
output <- readRDSFile()
newOutput <- list()
integerFields <- c("ID_PE", "newID_PE", "ID_PE_MES")
for (n in names(output)) {
  message("Processing ", n)
  df <- output[[n]]
  for (f in integerFields) {
    if (f %in% colnames(df)) {
      message("    Processing field ", f)
      if (class(df[,f]) %in% c("integer64", "integer", "numeric")) {
        df[,f] <- trimws(format(df[,f], scientific= F))
      }
    }
  }
  newOutput[[n]] <- df
}
saveRDS(newOutput, file = "./compilation/QcPSP.Rds", compress = "xz")
saveRDS(newOutput, file = "./inst/extdata/QcPSP.Rds", compress = "xz")



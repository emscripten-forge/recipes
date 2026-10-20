## To be imported from 'future', if available
FutureRegistry <- NULL
assertOwner <- NULL
readImmediateConditions <- NULL
signalEarly <- NULL
evalFuture <- NULL
getFutureData <- NULL
getFutureBackendConfigs <- NULL
sQuoteLabel <- NULL
.debug <- NULL

## Import private functions from 'future'
#' @importFrom utils packageVersion
import_future_functions <- function() {
  FutureRegistry <<- import_future("FutureRegistry")
  assertOwner <<- import_future("assertOwner")
  readImmediateConditions <<- import_future("readImmediateConditions")
  signalEarly <<- import_future("signalEarly")
  
  ## future (>= 1.40.0)
  evalFuture <<- import_future("evalFuture")
  getFutureData <<- import_future("getFutureData")
  getFutureBackendConfigs <<- import_future("getFutureBackendConfigs")
  # registerS3method("getFutureBackendConfigs", "CallrFuture", getFutureBackendConfigs.CallrFuture)

  ## future (>= 1.58.0)
  sQuoteLabel <<- import_future("sQuoteLabel")

  .debug <<- import_future(".debug", mode = "environment", default = new.env(parent = emptyenv()))
}


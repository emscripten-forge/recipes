CallrFutureBackend <- function(...) {
    future:::SequentialFutureBackend(...)
}

callr <- function(...) {
    stop("INTERNAL ERROR: future.callr::callr() must never be called directly")
}

class(callr) <- c("callr", "multiprocess", "future", "function")
attr(callr, "init") <- TRUE
attr(callr, "factory") <- CallrFutureBackend

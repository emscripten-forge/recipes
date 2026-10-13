library(bit64)

stopifnot(is.function(as.integer64))
x <- as.integer64(1:5)
stopifnot(inherits(x, "integer64"))
stopifnot(identical(as.integer(x), 1:5))

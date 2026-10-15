library(caTools)

stopifnot(is.function(runmean))
stopifnot(is.function(base64encode))

x <- 1:10
stopifnot(length(runmean(x, k = 3)) == length(x))

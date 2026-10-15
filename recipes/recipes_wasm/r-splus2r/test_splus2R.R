library(splus2R)

stopifnot(is.function(stdev))
stopifnot(is.function(peaks))

# Basic S-PLUS compatibility helpers
x <- c(1, 2, 3, 4, 5)
stopifnot(is.numeric(stdev(x)))

library(isoband)

stopifnot(is.function(isobands))
stopifnot(is.function(isolines))

m <- matrix(c(0, 0, 0, 0, 1, 0, 0, 0, 0), nrow = 3)
bands <- isobands(x = 1:3, y = 1:3, z = m, levels_low = 0.4, levels_high = 0.6)
stopifnot(is.list(bands))

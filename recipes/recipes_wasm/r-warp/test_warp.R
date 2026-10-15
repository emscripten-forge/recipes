library(warp)

stopifnot(is.function(warp_distance))

x <- as.Date(c("2019-01-01", "2019-01-02", "2019-01-08"))
stopifnot(is.numeric(warp_distance(x, period = "week")))

library(timechange)

stopifnot(is.function(time_add))
stopifnot(is.function(time_update))

x <- as.POSIXct("2020-01-01 12:00:00", tz = "UTC")
y <- time_add(x, hours = 1)
stopifnot(identical(as.numeric(difftime(y, x, units = "hours")), 1))

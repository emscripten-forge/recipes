library(lubridate)

stopifnot(is.function(ymd))
stopifnot(is.function(interval))

d <- ymd("2020-01-15")
stopifnot(inherits(d, "Date"))
stopifnot(identical(year(d), 2020))
stopifnot(identical(month(d), 1))

library(tzdb)

stopifnot(is.function(tzdb_names))
stopifnot(is.function(tzdb_version))

names <- tzdb_names()
stopifnot(is.character(names))
stopifnot(length(names) > 0L)

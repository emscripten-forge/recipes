library(utf8)

stopifnot(is.function(utf8_valid))
stopifnot(is.function(as_utf8))

stopifnot(utf8_valid("hello"))
stopifnot(identical(as_utf8("café"), "café"))

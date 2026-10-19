library(lazyeval)

stopifnot(is.function(lazy))
stopifnot(is.function(interp))

f <- function(x = a + b) {
  lazy(x)
}
e <- f(a + b)
stopifnot(inherits(e, "lazy"))

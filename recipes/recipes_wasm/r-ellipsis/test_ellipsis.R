library(ellipsis)

stopifnot(is.function(check_dots_used))
stopifnot(is.function(check_dots_unnamed))

f <- function(...) {
  check_dots_used()
  TRUE
}
stopifnot(isTRUE(f()))

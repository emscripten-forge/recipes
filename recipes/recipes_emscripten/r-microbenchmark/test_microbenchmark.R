library(microbenchmark)

result <- microbenchmark(sqrt(2), times = 10L)
stopifnot(!is.null(result))

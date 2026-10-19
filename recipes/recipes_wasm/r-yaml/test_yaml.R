library(yaml)

stopifnot(is.function(as.yaml))
stopifnot(is.function(yaml.load))

doc <- as.yaml(list(a = 1, b = "two"))
parsed <- yaml.load(doc)
stopifnot(identical(parsed$a, 1L) || identical(parsed$a, 1))
stopifnot(identical(parsed$b, "two"))

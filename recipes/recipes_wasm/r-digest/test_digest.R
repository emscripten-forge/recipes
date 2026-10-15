library(digest)

x <- digest("hello wasm", algo = "md5")
stopifnot(is.character(x), nchar(x) == 32L)
print(x)

library(jsonlite)

x <- list(a = 1:3, b = "wasm")
js <- toJSON(x)
y <- fromJSON(js)
stopifnot(identical(y$a, 1:3), identical(y$b, "wasm"))
print(js)

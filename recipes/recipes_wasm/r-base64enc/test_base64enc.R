library(base64enc)

stopifnot(is.function(base64encode))
stopifnot(is.function(base64decode))

x <- charToRaw("hello wasm")
y <- base64decode(base64encode(x))
print(y)
stopifnot(identical(x, y))

enc <- base64encode(x)
print(enc)
stopifnot(identical(enc, "aGVsbG8gd2FzbQ=="))

pkgdir <- system.file(package = "base64enc")
stopifnot(nzchar(pkgdir))

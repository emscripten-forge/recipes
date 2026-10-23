print('Loading zip package')
library(zip)
print('... zip package loaded successfully')

test_1 <- function() {
    stopifnot(is.function(deflate))
    stopifnot(is.function(inflate))
    stopifnot(is.function(zip))
    stopifnot(is.function(zip_list))
    stopifnot(is.function(unzip))
}

test_2 <- function() {
    data_gz <- deflate(charToRaw("Hello world!"))
    out <- inflate(data_gz$output)
    stopifnot(identical(rawToChar(out$output), "Hello world!"))
}

test_3 <- function() {
    tmp <- tempfile(fileext = ".zip")
    on.exit(unlink(tmp), add = TRUE)
    f <- tempfile()
    writeLines("zip test", f)
    on.exit(unlink(f), add = TRUE)
    zip(tmp, files = basename(f), root = dirname(f))
    listing <- zip_list(tmp)
    stopifnot(nrow(listing) >= 1L)
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()

print("Running test_3")
test_3()

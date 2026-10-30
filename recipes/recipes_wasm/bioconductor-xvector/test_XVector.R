library(XVector)

test_1 <- function() {
    x <- as(charToRaw("ACGT"), "XRaw")
    print(class(x))
    stopifnot(inherits(x, "XRaw"), length(x) == 4L)
}

test_2 <- function() {
    stopifnot(length(getNamespaceExports("XVector")) > 0)
    print(head(sort(getNamespaceExports("XVector")), 10))
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()

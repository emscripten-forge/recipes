library(Rhtslib)

test_1 <- function() {
    stopifnot(length(getNamespaceExports("Rhtslib")) >= 0)
    print(head(sort(getNamespaceExports("Rhtslib")), 10))
}

test_2 <- function() {
    path <- system.file(package = "Rhtslib")
    print(path)
    stopifnot(nzchar(path), dir.exists(path))
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()

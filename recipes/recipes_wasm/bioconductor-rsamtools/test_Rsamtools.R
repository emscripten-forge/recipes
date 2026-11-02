library(Rsamtools)

test_1 <- function() {
    stopifnot(is.function(BamFile) || exists("BamFile"))
    print(head(sort(getNamespaceExports("Rsamtools")), 10))
}

test_2 <- function() {
    path <- system.file("extdata", "ex1.bam", package = "Rsamtools", mustWork = TRUE)
    bf <- BamFile(path)
    print(bf)
    stopifnot(inherits(bf, "BamFile"))
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()

library(Biostrings)

test_1 <- function() {
    dna <- DNAString("ATGCGCTA")
    print(dna)
    stopifnot(inherits(dna, "DNAString"), length(dna) == 8L)
}

test_2 <- function() {
    aa <- AAString("ARND")
    print(aa)
    stopifnot(inherits(aa, "AAString"), length(aa) == 4L)
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()

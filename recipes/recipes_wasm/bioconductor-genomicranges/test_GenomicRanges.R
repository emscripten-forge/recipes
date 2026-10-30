library(GenomicRanges)

test_1 <- function() {
    gr <- GRanges(seqnames = "chr1", ranges = IRanges(1:3, width = 2), strand = "+")
    print(gr)
    stopifnot(inherits(gr, "GRanges"), length(gr) == 3L)
}

test_2 <- function() {
    gr <- GRanges("chr2:10-20")
    print(start(gr))
    stopifnot(start(gr) == 10L, end(gr) == 20L)
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()

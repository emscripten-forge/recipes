library(IRanges)

test_1 <- function() {
    ir <- IRanges(start = 1:3, width = 2)
    print(ir)
    stopifnot(inherits(ir, "IRanges"), length(ir) == 3L)
}

test_2 <- function() {
    ir <- IRanges(c(1, 5, 10), c(3, 7, 15))
    print(width(ir))
    stopifnot(all(width(ir) == c(3L, 3L, 6L)))
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()

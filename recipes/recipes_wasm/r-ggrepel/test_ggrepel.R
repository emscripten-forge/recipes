library(ggrepel)
library(ggplot2)

test_1 <- function() {
    stopifnot(is.function(geom_text_repel))
    stopifnot(is.function(geom_label_repel))
}

test_2 <- function() {
    p <- ggplot(mtcars, aes(wt, mpg, label = rownames(mtcars))) +
        geom_point() +
        geom_text_repel(max.overlaps = Inf)
    stopifnot(inherits(p, "ggplot"))
    print(p)
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()

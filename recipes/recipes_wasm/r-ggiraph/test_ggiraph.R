library(ggplot2)
library(ggiraph)

test_1 <- function() {
    plot_data <- data.frame(x = 1:3, y = c(1, 4, 2), label = letters[1:3])
    plot <- ggplot(plot_data, aes(x, y, tooltip = label)) +
      geom_point_interactive()
    widget <- girafe(ggobj = plot)
    stopifnot(inherits(widget, "girafe"))
    stopifnot(grepl("<svg", widget$x$html, fixed = TRUE))
    stopifnot(grepl("title='a'", widget$x$html, fixed = TRUE))
    print(class(widget))
}

test_2 <- function() {
    library(ggformula)
    gf_plot <- gf_boxplot(Sepal.Length ~ Species, data = iris)
    stopifnot(inherits(gf_plot, "ggplot"))
    print(class(gf_plot))
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()

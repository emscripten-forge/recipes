print('Loading systemfonts package')
library(systemfonts)
print('... systemfonts package loaded successfully')

test_1 <- function() {
    matched <- match_fonts("sans")
    stopifnot(nrow(matched) == 1L)
    stopifnot(file.exists(matched$path[[1]]))
}

test_2 <- function() {
    width <- string_width(
      c("Emscripten Forge", "Emscripten Forge"),
      family = "sans",
      size = c(10, 20)
    )
    stopifnot(all(is.finite(width)))
    stopifnot(width[[2]] > 1.8 * width[[1]])
}

test_3 <- function() {
    fonts <- system_fonts()
    stopifnot(is.data.frame(fonts))
    stopifnot(nrow(fonts) > 0L)
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()

print("Running test_3")
test_3()

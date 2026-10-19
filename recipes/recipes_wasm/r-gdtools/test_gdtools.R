print('Loading gdtools package')
library(gdtools)
print('... gdtools package loaded successfully')

test_1 <- function() {
    size <- strings_sizes(
      c("Emscripten Forge", "Emscripten Forge"),
      fontname = "sans",
      fontsize = c(10, 20)
    )
    stopifnot(all(is.finite(size$width)))
    stopifnot(size$width[[2]] > 1.8 * size$width[[1]])
    print(size)
}

print("Running test_1")
test_1()

library(gdtools)

size <- strings_sizes(
  c("Emscripten Forge", "Emscripten Forge"),
  fontname = "sans",
  fontsize = c(10, 20)
)
stopifnot(all(is.finite(size$width)))
stopifnot(size$width[[2]] > 1.8 * size$width[[1]])

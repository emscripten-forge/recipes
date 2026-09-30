library(systemfonts)

matched <- match_fonts("sans")
stopifnot(nrow(matched) == 1L)
stopifnot(file.exists(matched$path[[1]]))

width <- string_width(
  c("Emscripten Forge", "Emscripten Forge"),
  family = "sans",
  size = c(10, 20)
)
stopifnot(all(is.finite(width)))
stopifnot(width[[2]] > 1.8 * width[[1]])

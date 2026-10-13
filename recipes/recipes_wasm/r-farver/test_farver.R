library(farver)

rgb <- matrix(c(1, 0, 0), ncol = 3)
lab <- convert_colour(rgb, from = "rgb", to = "lab")
stopifnot(is.matrix(lab), ncol(lab) == 3L)
print(lab)

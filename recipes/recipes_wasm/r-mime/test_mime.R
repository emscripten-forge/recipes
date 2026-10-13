library(mime)

stopifnot(identical(guess_type("file.png"), "image/png"))
print(guess_type(c("a.html", "b.csv")))

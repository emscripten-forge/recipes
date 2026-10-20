library(rbibutils)

bibacc <- system.file("bib/latin1accents_utf8.bib", package = "rbibutils")

be0 <- readBib(bibacc)
be0
print(be0, style = "bibtex")

be1 <- readBib(bibacc, direct = TRUE)
## readBib(bibacc, direct = TRUE, texChars = "keep") # same
be1
print(be1, style = "bibtex")

be2 <- readBib(bibacc, direct = TRUE, texChars = "convert")
be2
print(be2, style = "R")

be3 <- readBib(bibacc, direct = TRUE, texChars = "export")
print(be3, style = "bibtex")

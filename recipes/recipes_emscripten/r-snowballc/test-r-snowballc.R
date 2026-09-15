library(SnowballC)

stopifnot(is.function(getStemLanguages))
stopifnot(is.function(wordStem))

# Example from SnowballC documentation
wordStem(c("win", "winning", "winner"))
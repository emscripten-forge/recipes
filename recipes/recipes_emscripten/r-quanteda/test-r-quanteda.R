library(quanteda)

stopifnot(is.function(corpus_reshape))
stopifnot(is.function(dfm))
stopifnot(is.function(bootstrap_dfm))

# Example from documentation
set.seed(10)
txt <- c(textone = "This is a sentence.  Another sentence.  Yet another.",
         texttwo = "Premiere phrase.  Deuxieme phrase.")
dfmat <- corpus_reshape(corpus(txt), to = "sentences") |>
    tokens() |>
    dfm()
bootstrap_dfm(dfmat, n = 3)
print('Loading quanteda package')
library(quanteda)
print('... quanteda package loaded successfully')

test_1 <- function() {
    library(quanteda)
    stopifnot(is.function(corpus_reshape))
    stopifnot(is.function(dfm))
    stopifnot(is.function(bootstrap_dfm))
}

test_2 <- function() {
    library(quanteda)
    # Example from documentation
    set.seed(10)
    txt <- c(textone = "This is a sentence.  Another sentence.  Yet another.",
             texttwo = "Premiere phrase.  Deuxieme phrase.")
    dfmat <- corpus_reshape(corpus(txt), to = "sentences") |>
        tokens() |>
        dfm()
    print(bootstrap_dfm(dfmat, n = 3))
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()

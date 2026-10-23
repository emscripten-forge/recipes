library(sweater)

test_1 <- function() {
    stopifnot(is.function(semaxis))
    stopifnot(is.function(weat_es))
    stopifnot(is.function(weat))
}

test_2 <- function() {
    # Example from sweater documentation
    data(glove_math)
    S1 <- c("math", "algebra", "geometry", "calculus", "equations",
            "computation", "numbers", "addition")
    A1 <- c("male", "man", "boy", "brother", "he", "him", "his", "son")
    B1 <- c("female", "woman", "girl", "sister", "she", "her", "hers", "daughter")
    result <- semaxis(glove_math, S1, A1, B1, l = 0)$P
    print(result)
    stopifnot(is.numeric(result))
}

test_3 <- function() {
    # Reproduce the number in Caliskan et al. (2017) - Table 1, "Math vs. Arts"
    data(glove_math)
    S1 <- c("math", "algebra", "geometry", "calculus", "equations",
            "computation", "numbers", "addition")
    T1 <- c("poetry", "art", "dance", "literature", "novel", "symphony", "drama", "sculpture")
    A1 <- c("male", "man", "boy", "brother", "he", "him", "his", "son")
    B1 <- c("female", "woman", "girl", "sister", "she", "her", "hers", "daughter")
    sw <- weat(glove_math, S1, T1, A1, B1)
    es <- weat_es(sw)
    print(es)
    stopifnot(is.numeric(es))
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()

print("Running test_3")
test_3()

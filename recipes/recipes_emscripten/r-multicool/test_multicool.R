library(multicool)
test_1 <- function() {

    ## returns B(6)
    Bell(6)

    ## returns B(1), B(2), ..., B(6)
    B(1:6)
}

test_2 <- function() {

    ## returns S(6, 3)
    Stirling2(6, 3)

    ## returns S(6,1), S(6,2), ..., S(6,6)
    S2(6, 1:6)

    ## returns S(6,1), S(5, 2), S(4, 3)
    S2(6:4, 1:3)
}

test_3 <- function() {

    ## a small numeric example with 6 permuations
    x = c(1,1,2,2)
    m = initMC(x)
    allPerm(m)

    ## a large character example - 60 possibilities
    x = rep(letters[1:3], 3:1)
    multinom(x) ## calculate the number of permutations
    m = initMC(x)
    allPerm(m)
}

test_4 <- function() {

    ## a small numeric example with all 11 partitions of 6
    genComp(6)

    ## a small example with the integer partitions of 6 of length 3 with empty partitions added
    genComp(6, 3, TRUE)

    ## a larger example - 627 partions of 20, but restricted to those of length 3 or smaller
    genComp(20, 3)
}

test_5 <- function() {

    x = c(1,1,2,2)
    m1 = initMC(x)
    m1

    ## a non-integer example

    x = rep(letters[1:4],c(2,1,2,2))
    m2 = initMC(x)
    m2
}

test_6 <- function() {

    x = c(1,1,2,2)
    m1 = initMC(x)

    for(i in 1:6){
      cat(paste(paste(nextPerm(m1),collapse=","),"\n"))
    }

    ## an example with letters
    x = letters[1:4]
    m2 = initMC(x)
    nextPerm(m2)
    nextPerm(m2)
    ## and so on
}

cat("Running test_1\n")
test_1()

cat("Running test_2\n")
test_2()

cat("Running test_3\n")
test_3()

cat("Running test_4\n")
test_4()

cat("Running test_5\n")
test_5()

cat("Running test_6\n")
test_6()


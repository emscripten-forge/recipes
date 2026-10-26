print('Loading randtoolbox package')
library(rngWELL)
library(randtoolbox)
print('... randtoolbox package loaded successfully')

test_1 <- function() {

    # should be 1
    stirling(0)

    #  should be 0,1,7,6,1
    stirling(4)
}

test_2 <- function() {
    # (1) poisson approximation
    #
    coll.test(runif, 2^7, 2^10, 1, 100)

    # (2) exact distribution
    #
    coll.test(SFMT, 2^7, 2^10, 1, 100)
}

test_3 <- function() {
    # (1) 
    #
    freq.test(runif(1000))
    print( freq.test( runif(10000), echo=FALSE) )

    # (2) 
    #
    freq.test(runif(1000), 1:4)

    freq.test(runif(1000), 10:40)
}

test_4 <- function() {
    # (1) 
    #
    gap.test(runif(1000))
    print( gap.test( runif(1000000), echo=FALSE ) )

    # (2) 
    #
    gap.test(runif(1000), 1/3, 2/3)
}

test_5 <- function() {
    p <- get.primes(20)
    torus(5,dim=10,prime=p[11:20])
}

test_6 <- function() {
    # (1) mersenne twister vs torus
    #
    order.test(runif(6000))
    order.test(torus(6000))

    # (2) 
    #
    order.test(runif(4000), 4)
    order.test(torus(4000), 4)

    # (3) 
    #
    order.test(runif(5000), 5)
    order.test(torus(5000), 5)
}

test_7 <- function() {
    # (1) hands of 5 'cards'
    #
    poker.test(runif(50000))

    # (2) hands of 4 'cards'
    #
    poker.test(runif(40000), 4)

    # (3) hands of 42 'cards'
    #
    poker.test(runif(420000), 42)
}

# NOTE: set.generator() + RNGkind("user-supplied") does not work on WebAssembly.
# That path registers C function pointers (user_unif_rand / user_unif_init) across
# R's MAIN_MODULE and the randtoolbox/rngWELL SIDE_MODULEs. Emscripten then fails
# with "RuntimeError: table index is out of bounds" on call_indirect.
# Use direct APIs (WELL(), congruRand(), setSeed(), setSeed4WELL()) instead.

test_8 <- function() {
      # WELL512a via direct API (avoids user-supplied RNG)
      print("WELL512a via WELL()")
      setSeed4WELL(123456)
      x <- WELL(500, order = 512, version = "a")
      stopifnot(is.numeric(x), length(x) == 500L)
      stopifnot(all(x >= 0), all(x <= 1))
}

test_9 <- function() {
    # WELL19937a via direct API
    print("WELL19937a via WELL()")
    setSeed4WELL(12345)
    x <- WELL(5, order = 19937, version = "a")
    stopifnot(length(x) == 5L)

    # Park Miller congruential generator (direct API)
    setSeed(12345)
    congruRand(5, dim = 1, mod = 2^31 - 1, mult = 16807, incr = 0)

    # Knuth Lewis RNG (direct API)
    setSeed(1)
    congruRand(5, dim = 1, mod = 4294967296, mult = 1664525, incr = 1013904223)

    # SFMT / Mersenne Twister via direct API (avoids set.generator user-supplied)
    print(SFMT(5, dim = 1))
}

test_10 <- function() {
    # (1) 
    #
    serial.test(runif(1000))
    print( serial.test( runif(1000000), d=2, e=FALSE) )

    # (2) 
    #
    serial.test(runif(5000), 5)
}

test_11 <- function() {
    #page 306 of Glassermann
    sobol.R(10,2)
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()

print("Running test_3")
test_3()

print("Running test_4")
test_4()

print("Running test_5")
test_5()

print("Running test_6")
test_6()


print("Running test_7")
test_7()

print("Running test_8")
test_8()

print("Running test_9")
test_9()

print("Running test_10")
test_10()

print("Running test_11")
test_11()


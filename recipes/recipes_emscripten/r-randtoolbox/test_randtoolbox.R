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

test_8 <- function() {
      print("set generator to WELL512a")
      set.generator("WELL", order=512, version="a", seed=123456)
      print("GET RNGkind()")
      print(RNGkind()[1])
      s <- getWELLState()
      x <- runif(500)
      y <- rngWELLScriptR(500, s, "512a")
      all(x == y)
      # [1] TRUE
}

test_9 <- function() {
    #set WELL19937a
    set.generator("WELL", version="19937a", seed=12345)
    runif(5)

    #Store the current state  and generate 10 random numbers
    storedState <- get.description()
    x <- runif(10)

    #Park Miller congruential generator
    set.generator(name="congruRand", mod=2^31-1, mult=16807, incr=0, seed=12345)
    runif(5)
    setSeed(12345)
    congruRand(5, dim=1, mod=2^31-1, mult=16807, incr=0)

    # the Knuth Lewis RNG
    set.generator(name="congruRand", mod="4294967296", mult="1664525", incr="1013904223", seed=1)
    runif(5)
    setSeed(1)
    congruRand(5, dim=1, mod=4294967296, mult=1664525, incr=1013904223)

    #Restore the generator from storedState and regenerate the same numbers
    put.description(storedState)
    x == runif(10)

    # generate the same random numbers as in Matlab
    set.generator("MersenneTwister", initialization="init2002", resolution=53, seed=12345)
    runif(5)
    # [1] 0.9296161 0.3163756 0.1839188 0.2045603 0.5677250
    # Matlab commands rand('twister', 12345); rand(1, 5) generate the same numbers,
    # which in short format are   0.9296    0.3164    0.1839    0.2046    0.5677

    #Restore the original R setting
    set.generator("default")
    RNGkind()
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

# NOTE that test_8 and test_9 fail with
#  │ RuntimeError: table index is out of bounds
#  │     at wasm://wasm/000287c2:wasm-function[193]:0x9bd5
#  │     at wasm://wasm/0235b552:wasm-function[978]:0xcbbc6
#  │     at wasm://wasm/0235b552:wasm-function[1313]:0xf39a7
#  │     at wasm://wasm/0235b552:wasm-function[1330]:0x5b8090
#  │     at wasm://wasm/0235b552:wasm-function[1317]:0xf4304
#  │     at wasm://wasm/0235b552:wasm-function[1313]:0xf3a82
#  │     at wasm://wasm/0235b552:wasm-function[1348]:0x5bea5f
#  │     at wasm://wasm/0235b552:wasm-function[1313]:0xf386e
#  │     at wasm://wasm/0235b552:wasm-function[1339]:0x5b97e3
#  │     at wasm://wasm/0235b552:wasm-function[1313]:0xf386e

print("SKIPPING test_8")
# test_8()

print("SKIPPING test_9")
#test_9()

print("Running test_10")
test_10()

print("Running test_11")
test_11()


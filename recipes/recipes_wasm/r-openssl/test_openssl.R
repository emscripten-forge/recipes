print('Loading openssl package')
library(openssl)
print('... openssl package loaded successfully')

test_1 <- function() {
    print(openssl_config())
}

test_2 <- function() {
    test_string <- "Hello, OpenSSL!"
    hash <- sha256(test_string)
    print(hash)
    stopifnot(nchar(hash) == 64)
}

test_3 <- function() {
    key <- rsa_keygen()
    print(key)
    stopifnot(inherits(key, "key"))
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()

print("Running test_3")
test_3()

library(openssl)

# Test SHA256 hashing
test_string <- "Hello, OpenSSL!"
hash <- sha256(test_string)
print(hash)

# Test RSA encryption and decryption
key <- rsa_keygen()
print(key)
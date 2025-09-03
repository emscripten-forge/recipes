import primesieve

print("Testing primesieve import...")

# Test basic functionality
primes = primesieve.generate_primes(100)
print(f"Primes up to 100: {len(primes)} primes found")

# Test count function
count = primesieve.count_primes(1000)
print(f"Number of primes up to 1000: {count}")

print("primesieve import and basic functionality test passed!")
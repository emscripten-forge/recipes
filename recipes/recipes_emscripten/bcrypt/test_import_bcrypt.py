import bcrypt

# Test basic functionality
password = b"super secret password"
hashed = bcrypt.hashpw(password, bcrypt.gensalt())
assert bcrypt.checkpw(password, hashed)
assert not bcrypt.checkpw(b"wrong password", hashed)

print("bcrypt import and basic functionality test passed")
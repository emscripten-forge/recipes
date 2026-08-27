# 1. Load the library (tests if the compiled library can be loaded)
library(ipred)

# 2. Create a tiny dummy dataset
set.seed(42)
mock_data <- data.frame(
  x1 = rnorm(20),
  x2 = rnorm(20),
  y  = as.factor(sample(c("A", "B"), 20, replace = TRUE))
)

# 3. Train a minimal bagging model (tests C/Fortran compiled clustering/trees)
# We use just 2 bootstrap replications to keep it instant
test_model <- ipredbagg(y ~ x1 + x2, data = mock_data, nbagg = 2)

# 4. Predict on the same data (tests prediction engine)
predictions <- predict(test_model, newdata = mock_data)

# 5. Verify it worked
print("IPRED check passed successfully!")
print(head(predictions))

# 1. Load the library
library(KernSmooth)

# 2. Create a tiny vector of numeric data
set.seed(42)
mock_data <- rnorm(30)

# 3. Estimate the optimal bandwidth (triggers Fortran-level calculations)
# dpik evaluates a plug-in bandwidth selection
bandwidth <- dpik(mock_data)

# 4. Perform a 1D local linear kernel smooth (triggers the core Fortran backend)
smooth_result <- bkde(mock_data, bandwidth = bandwidth)

# 5. Verify it worked by printing the structure
print("KernSmooth check passed successfully!")
print(head(data.frame(x = smooth_result$x, y = smooth_result$y)))
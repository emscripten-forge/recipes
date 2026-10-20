library(fOptions)

# European Black-Scholes call option
result <- GBSOption(
  TypeFlag = "c",   # Call option
  S = 100,          # Spot price
  X = 100,          # Strike price
  Time = 1,         # 1 year to maturity
  r = 0.05,         # Risk-free rate
  b = 0.05,         # Cost of carry
  sigma = 0.20      # Volatility
)

# Print results
print(result)
cat("Option price:", result@price, "\n")
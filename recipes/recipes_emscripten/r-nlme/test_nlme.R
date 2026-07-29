library(nlme)

# ------------------------------------------------------------------------------
# Test 1: gls with trigonometric terms using Ovary dataset
# ------------------------------------------------------------------------------

# The Ovary dataset is built into nlme
# It contains follicular growth in mares over time
data(Ovary)
print(head(Ovary))

# Fit gls model with sin and cos terms
fm1 <- gls(follicles ~ sin(2*pi*Time) + cos(2*pi*Time), 
           data = Ovary)

# Display summary
print(summary(fm1))

# Check that coefficients are reasonable
stopifnot(all(!is.na(coef(fm1))))
stopifnot(all(is.finite(coef(fm1))))

# Compute autocorrelation function
acf_result <- ACF(fm1, form = ~ 1 | Mare)
print(head(acf_result))

# Check ACF results
stopifnot(is.data.frame(acf_result))
stopifnot(nrow(acf_result) > 0)

# ------------------------------------------------------------------------------
# Test 2: gls with polynomial terms using Dialyzer dataset
# ------------------------------------------------------------------------------

# The Dialyzer dataset is built into nlme
# It contains data from hemodialyzers
data(Dialyzer)
print(head(Dialyzer))

# Fit gls model with polynomial terms
fm1Dial.gls <- gls(rate ~ (pressure + I(pressure^2) + I(pressure^3) + I(pressure^4)) * QB,
                   data = Dialyzer)

# Display summary
print(summary(fm1Dial.gls))

# Check that coefficients are reasonable
stopifnot(all(!is.na(coef(fm1Dial.gls))))
stopifnot(all(is.finite(coef(fm1Dial.gls))))

# ------------------------------------------------------------------------------
# Test 3: Update gls with variance weights
# ------------------------------------------------------------------------------

# Update model with variance weights
fm2Dial.gls <- update(fm1Dial.gls,
                      weights = varPower(form = ~ pressure))

# Display summary
print(summary(fm2Dial.gls))

# Check that weights were added
stopifnot(!is.null(fm2Dial.gls$modelStruct$varStruct))

# Compute ACF for the updated model
acf_result2 <- ACF(fm2Dial.gls, form = ~ 1 | Subject)
print(head(acf_result2))

# Check ACF results
stopifnot(is.data.frame(acf_result2))
stopifnot(nrow(acf_result2) > 0)

# ------------------------------------------------------------------------------
# Test 4: Compare models
# ------------------------------------------------------------------------------

# Compare AIC values
aic1 <- AIC(fm1Dial.gls)
aic2 <- AIC(fm2Dial.gls)
cat("AIC without weights:", aic1, "\n")
cat("AIC with varPower weights:", aic2, "\n")

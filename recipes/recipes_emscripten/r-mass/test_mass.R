library(MASS)

# ------------------------------------------------------------------------------
# Test 1: Poisson GLM with offset using Insurance dataset
# ------------------------------------------------------------------------------

# Fit Poisson GLM with offset
fit_glm <- glm(Claims ~ District + Group + Age + offset(log(Holders)),
               data = Insurance, family = poisson)

# Display summary
print(summary(fit_glm))

# Check that coefficients are reasonable (non-NA, finite)
stopifnot(all(!is.na(coef(fit_glm))))
stopifnot(all(is.finite(coef(fit_glm))))

# ------------------------------------------------------------------------------
# Test 2: loglm with offset (equivalent to Poisson GLM)
# ------------------------------------------------------------------------------

# Fit log-linear model with offset
fit_loglm <- loglm(Claims ~ District + Group + Age + offset(log(Holders)),
                   data = Insurance)

# Display results
print(fit_loglm)

# Check that the model converged (non-NA fitted values)
stopifnot(!is.na(fit_loglm$fitted))

# Compare GLM and loglm fitted values
glm_fitted <- fitted(fit_glm)
loglm_fitted <- fit_loglm$fitted
diff_max <- max(abs(glm_fitted - loglm_fitted))
cat("Maximum difference in fitted values:", diff_max, "\n")
stopifnot(diff_max < 1e-6)

# ------------------------------------------------------------------------------
# Test 3: Utility functions (enlist, fbeta, nclass.freq)
# ------------------------------------------------------------------------------

# Test enlist
vec <- c(a = 1, b = 2, c = 3)
enlisted <- enlist(vec)
print(enlisted)
stopifnot(is.list(enlisted))
stopifnot(length(enlisted) == length(vec))

# Test fbeta
x <- seq(0, 1, length.out = 5)
alpha <- 2
beta <- 3
result <- fbeta(x, alpha, beta)
print(result)
stopifnot(length(result) == length(x))
stopifnot(all(is.finite(result)))

# Test nclass.freq
test_data <- c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
nclass_result <- nclass.freq(test_data)
print(paste("Number of classes:", nclass_result))
stopifnot(is.numeric(nclass_result))
stopifnot(nclass_result > 0)

